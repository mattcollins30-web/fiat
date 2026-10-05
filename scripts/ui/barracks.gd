extends Control
## The Caravan's screen: what the runner was, and training. Three trees as
## three columns - the class's first, the yard's, the class's second - a chain
## each, read top down; a node lit when taken, open when it's next, dim when
## it isn't. Under them a panel for the selected node and the Train and
## Respec buttons. Fixed geometry inside the card grid's 1536 x 864.

signal acted
signal ascend                      # the Second past button: the owner offers the classes

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const People := preload("res://scripts/ui/people.gd")
const Words := preload("res://scripts/sim/words.gd")

const COL_GAP := 16
const COL_W := (Pal.GRID_W - 2 * COL_GAP) / 3                 # 501
const CLASS_H := 52                                            # the class bar across the top
const TREE_Y := CLASS_H + 16
const HEAD_H := 40
const SWAP_W := 210                                            # the middle head's "Next: … ▸"
const NODE_H := 40
const NODE_GAP := 5
const NODES_Y := TREE_Y + HEAD_H + 6
const PANEL_Y := NODES_Y + 12 * (NODE_H + NODE_GAP) - NODE_GAP + 16     # 650
const PANEL_H := Pal.ROOM_H - PANEL_Y                          # 214
const PAD := 20

var sim
var selected := ""                 # a node id, or ""
var _class_buttons: Array = []
var _class_words: Label
const ROWS := 12                   # the yard's tree is 12 deep; a class tree 8
var _heads: Array = []             # a column each: {name, count}
var _rows: Array = []              # [column][row] -> {button, name, effect, id}
var _shown_trees := ""
var _panel: Panel
var _face: TextureRect             # the class's portrait, at the panel's left, when there is one
var _title: Label
var _words: Label
var _points: Label
var _past: Label                   # the runners before this one
var _ascend: Button                # the second past, from level 30
var _swap: Button                  # over the middle column's head: cycles the yard's tree, the second past's, the elements'
var mid := 0                       # which of the middle trees shows
var drawer_page := 0               # the drawer's page: PAGE papers at a time
const PAGE := 6
var _train: Button
var _respec: Button
var _shown := ""


func _init() -> void:
	size = Vector2(Pal.GRID_W, Pal.ROOM_H)
	mouse_filter = Control.MOUSE_FILTER_PASS
	# the class bar: a button a class, the chosen one lit
	var cw := (Pal.GRID_W - COL_GAP * (Data.CLASSES.size() - 1)) / Data.CLASSES.size()
	for k in range(Data.CLASSES.size()):
		var cb := UI.button(self, Rect2(k * (cw + COL_GAP), 0, cw, CLASS_H), false)
		cb.text = Data.CLASSES[k]["name"]
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
		var col := []
		for i in range(ROWS):
			var btn := Button.new()
			btn.position = Vector2(x, NODES_Y + i * (NODE_H + NODE_GAP))
			btn.size = Vector2(COL_W, NODE_H)
			btn.text = ""
			btn.focus_mode = Control.FOCUS_ALL
			btn.pressed.connect(_pick_at.bind(b, i))
			add_child(btn)
			var n := {"button": btn, "id": "", "x": x}
			n["name"] = UI.label(btn, Rect2(PAD, 0, COL_W - 2 * PAD, NODE_H), "", "Regular", Pal.FLOOR, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
			n["effect"] = UI.label(btn, Rect2(PAD, 0, COL_W - 2 * PAD, NODE_H), "", "Medium", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_RIGHT, false)
			col.append(n)
		_rows.append(col)
	_panel = UI.panel(self, Rect2(0, PANEL_Y, Pal.GRID_W, PANEL_H), UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	_face = People.rect(_panel, Vector2(PAD, (PANEL_H - 128) / 2), 1)
	_title = UI.label(_panel, Rect2(PAD, 14, Pal.GRID_W - 2 * PAD - 260, 36), "", "SemiBold", Pal.TITLE, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
	_words = UI.label(_panel, Rect2(PAD, 56, Pal.GRID_W - 2 * PAD - 260, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_points = UI.label(_panel, Rect2(PAD, 90, Pal.GRID_W - 2 * PAD - 260, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	_past = UI.label(_panel, Rect2(PAD, 124, Pal.GRID_W - 2 * PAD - 520, 30), "", "Regular", Pal.FLOOR, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_train = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 200, Pal.BUTTON_H), true)
	_train.pressed.connect(_on_train)
	_respec = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 240, Pal.BUTTON_H), false)
	_respec.pressed.connect(_on_respec)
	_ascend = UI.button(_panel, Rect2(0, PANEL_H - PAD - Pal.BUTTON_H, 240, Pal.BUTTON_H), false)
	_ascend.pressed.connect(func(): ascend.emit())
	_ascend.visible = false
	_swap = UI.button(self, Rect2(COL_W + COL_GAP + COL_W - SWAP_W, TREE_Y, SWAP_W, HEAD_H), false)
	_swap.pressed.connect(_on_swap)
	_swap.visible = false


const EFFECT_WORDS := {
	"damage_pct": "+%d%% damage", "hp": "+%d max HP", "loot_pct": "+%d%% loot find", "search_pct": "Search %d%% faster",
	"first_pct": "First shot +%d%%", "patrol_pct": "Gangs %d%% later", "armour_pct": "Armour +%d%%", "heal_pct": "Meds +%d%%",
	"med_speed_pct": "Meds %d%% quicker", "med_cap": "+%d med carried", "rest_pct": "Rest +%d%%", "treat_pct": "Treatment −%d%%",
	"att_share": "+%d%% attachments", "sell_pct": "Fence pays +%d%%", "cash_pct": "Cash +%d%%", "rarity": "Rarer finds +%d%%",
	"pace_pct": "+%d%% pace", "damage_low_pct": "+%d%% dmg under ½ HP",
	"conv_fire_pct": "%d%% as fire", "conv_frost_pct": "%d%% as frost", "conv_poison_pct": "%d%% as poison", "conv_shock_pct": "%d%% as shock", "conv_bleed_pct": "%d%% as bleed",
	"fire_pct": "+%d%% fire", "frost_pct": "+%d%% frost", "poison_pct": "+%d%% poison", "shock_pct": "+%d%% shock", "bleed_pct": "+%d%% bleed", "physical_pct": "+%d%% physical",
	"dot_pct": "+%d%% dots",
}
const TYPE_WORDS := {"rifle": "rifles", "shotgun": "shotguns", "smg": "SMGs", "improvised": "improvised", "pistol": "pistols", "melee": "melee"}


static func _effect_words(nd: Dictionary) -> String:
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
	var sig := "%s|%s|%d|%d|%s|%s|%d|%s|%d|%d" % [selected, str(sim.tree), sim.training_points, int(sim.cash), sim.cls, str(sim.on_mission()), mid, sim.cls2, sim.book.size(), drawer_page]
	if sig == _shown:
		return
	_shown = sig
	for k in range(Data.CLASSES.size()):
		var cb: Button = _class_buttons[k]
		var name: String = Data.CLASSES[k]["name"]
		cb.text = name if sim.cls != name else "%s ✓" % name
		cb.disabled = sim.on_mission()
		UI.style_button(cb, sim.cls == name)
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
	var next_name: String = mids[(mid + 1) % mids.size()]["name"] if mids.size() > 1 else ""
	_swap.text = ("Next: %s ▸" % next_name) if mids.size() > 1 else ""
	_swap.add_theme_stylebox_override("normal", UI.box(Color.TRANSPARENT, 8))
	_swap.add_theme_stylebox_override("hover", UI.box(Color(Pal.CARD, 0.5), 8))
	_swap.add_theme_font_size_override("font_size", 18)
	for b in range(3):
		var branch = cols[b]
		var h: Dictionary = _heads[b]
		h["panel"].visible = branch != null
		if branch == null:
			for i in range(ROWS):
				_rows[b][i]["button"].visible = false
				_rows[b][i]["id"] = ""
			continue
		var taken := 0
		var who: String = branch.get("class", "")
		# the middle head shares its row with the swap button: the name fits what's left
		h["name"].size.x = COL_W - 2 * PAD - (SWAP_W if (b == 1 and _swap.visible) else 0)
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
			var stacked := _place(n, branch, i)
			var cost: int = sim.node_cost(id)
			var pts := "%d pt%s" % [cost, "" if cost == 1 else "s"]
			# a stacked node (on a branch) carries its cost in the name line, its effect under
			n["name"].add_theme_font_override("font", UI.font("SemiBold" if (nd.get("notable", false) or nd.get("keystone", false)) else "Regular"))
			if stacked:
				UI.fit(n["name"], ["%s · %s" % [nd["name"], pts], nd["name"]])
				if n["name"].text == nd["name"]:
					UI.fit(n["effect"], ["%s · %s" % [_effect_words(nd), pts], _effect_words(nd)])   # the cost moves down when the name's long
				else:
					n["effect"].text = _effect_words(nd)
			else:
				n["name"].text = nd["name"]
				n["effect"].text = "%s · %s" % [_effect_words(nd), pts]
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
		h["count"].text = "%d of %d" % [taken, branch["nodes"].size()]
		h["count"].visible = not (b == 1 and _swap.visible)      # the swap sits where the count would
	_show_panel()


func _show_panel() -> void:
	_train.visible = false
	# the runner's face at the left, the words beside it; no class, no face
	var faced := People.show(_face, sim.cls)
	for l in [_title, _words, _points]:
		l.position.x = PAD + 148 if faced else PAD
		l.size.x = Pal.GRID_W - 2 * PAD - 260 - (148 if faced else 0)
	_past.position.x = PAD + 148 if faced else PAD
	var free: int = sim.points_free()
	_points.text = "%d point%s free of %d earned · one a level · changing class refunds its two trees" % [free, "" if free == 1 else "s", sim.training_points]
	if selected == "":
		var cd: Dictionary = sim.class_data()
		if cd.is_empty():
			_title.text = "No past yet"
			_words.text = "Pick one above: what the runner was, and how they fight now. Free to change in the yard"
		else:
			var td: Dictionary = sim.trait_data()
			_title.text = ("%s · %s" % [cd["name"], td["name"]]) if not td.is_empty() else "%s" % cd["name"]
			UI.fit(_words, [cd["words"] + ((" · %s" % td["words"]) if not td.is_empty() else ""), cd["words"]])
	else:
		var nd: Dictionary = sim.node(selected)
		if nd.is_empty():
			selected = ""
			_show_panel()
			return
		_title.text = nd["name"] + (" · keystone" if nd.get("keystone", false) else (" · notable" if nd.get("notable", false) else ""))
		if nd.has("words"):
			_words.text = nd["words"]
		else:
			_words.text = _effect_words(nd) + ", for every runner the yard sends"
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
	if _train.visible:
		x -= 12 + _train.size.x
		_train.position.x = x
	# the runners before, in what's left beside the buttons
	_past.size.x = x - 12 - _past.position.x
	_show_past()


# ------------------------------------------------------------------ acting

## The runners before this one, newest first: who, how long, how it ended.
func _show_past() -> void:
	if sim.past.is_empty():
		# no one before this runner: what this one was, instead
		UI.fit(_past, [Words.PASTS[sim.cls]["was"] if Words.PASTS.has(sim.cls) else "", ""])
		return
	var long := []
	var short := []
	for k in range(sim.past.size() - 1, -1, -1):
		var r: Dictionary = sim.past[k]
		long.append("a %s, %d run%s, %s" % [str(r["class"]).to_lower(), int(r["runs"]), "" if int(r["runs"]) == 1 else "s", r["end"]])
		short.append("%s %d" % [str(r["class"]).to_lower(), int(r["runs"])])
	UI.fit(_past, ["Before: " + "; ".join(long), "Before: " + ", ".join(short), "%d runner%s before this one" % [sim.past.size(), "" if sim.past.size() == 1 else "s"]])


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


## Where a node sits: a class tree is a web - the spine down the column to
## its notable, then the two branches side by side under it, keystone's on
## the left, the rule's on the right, each node its name over its effect.
## The yard's tree is a ladder and stays one.
const BRANCH_H := NODE_H * 2 + NODE_GAP            # a stacked node is two rows tall
const BRANCH_PAD := 10
func _place(n: Dictionary, branch: Dictionary, i: int) -> bool:
	var b: Button = n["button"]
	var x: float = n["x"]
	b.position.x = x
	var fork := _fork_at(branch)
	var stacked: bool = fork >= 0 and i > fork
	if not stacked:
		b.position.y = NODES_Y + i * (NODE_H + NODE_GAP)
		b.size = Vector2(COL_W, NODE_H)
		n["name"].position = Vector2(PAD, 0)
		n["name"].size = Vector2(COL_W - 2 * PAD, NODE_H)
		n["effect"].position = Vector2(PAD, 0)
		n["effect"].size = Vector2(COL_W - 2 * PAD, NODE_H)
		n["effect"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		return false
	# which branch, and how far along it: the first branch after the fork is the keystone's
	var half := (COL_W - COL_GAP) / 2
	var k := i - fork - 1
	var per: int = (branch["nodes"].size() - fork - 1) / 2
	var side := k / per
	var row := k % per
	b.position.y = NODES_Y + (fork + 1) * (NODE_H + NODE_GAP) + row * (BRANCH_H + NODE_GAP)
	b.position.x = x + side * (half + COL_GAP)
	b.size = Vector2(half, BRANCH_H)
	n["name"].position = Vector2(BRANCH_PAD, 4)
	n["name"].size = Vector2(half - 2 * BRANCH_PAD, NODE_H - 4)
	n["effect"].position = Vector2(BRANCH_PAD, NODE_H - 2)
	n["effect"].size = Vector2(half - 2 * BRANCH_PAD, NODE_H - 4)
	n["effect"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return true


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
	return out


## The drawer, as a column: the papers found so far, in the order found,
## PAGE a page; a click on any of them turns the page.
func _drawer_branch() -> Dictionary:
	var pages: int = maxi(1, ceili(float(sim.book.size()) / PAGE))
	drawer_page = drawer_page % pages
	var nodes: Array = []
	var start: int = drawer_page * PAGE
	for k in range(start, mini(sim.book.size(), start + PAGE)):
		nodes.append({"name": "%d. %s" % [k + 1, sim.book[k]], "words": Words.item_words(sim.book[k])})
	if nodes.is_empty():
		nodes.append({"name": Words.BOOK["empty"], "words": ""})
	return {"name": "The drawer", "drawer": true, "nodes": nodes, "pages": pages}


func _show_drawer(b: int, branch: Dictionary) -> void:
	var h: Dictionary = _heads[b]
	var total: int = sim.book_pages().size()
	var page := (" · page %d of %d" % [drawer_page + 1, int(branch["pages"])]) if int(branch["pages"]) > 1 else ""
	var short_page := (" · p%d/%d" % [drawer_page + 1, int(branch["pages"])]) if int(branch["pages"]) > 1 else ""
	UI.fit(h["name"], ["The drawer · " + Words.BOOK["count"] % [sim.book.size(), total] + page, "Drawer · %d of %d%s" % [sim.book.size(), total, short_page], "Drawer %d/%d%s" % [sim.book.size(), total, short_page], "%d/%d%s" % [sim.book.size(), total, short_page], "The drawer"])
	h["count"].visible = false
	for i in range(ROWS):
		var n: Dictionary = _rows[b][i]
		if i >= branch["nodes"].size():
			n["button"].visible = false
			n["id"] = ""
			continue
		var nd: Dictionary = branch["nodes"][i]
		var btn: Button = n["button"]
		btn.visible = true
		btn.position = Vector2(n["x"], NODES_Y + i * (BRANCH_H + NODE_GAP))
		btn.size = Vector2(COL_W, BRANCH_H)
		n["id"] = "drawer/%d" % i
		n["name"].position = Vector2(PAD, 4)
		n["name"].size = Vector2(COL_W - 2 * PAD, NODE_H - 4)
		n["name"].add_theme_font_override("font", UI.font("SemiBold" if nd["words"] != "" else "Regular"))
		UI.fit(n["name"], [nd["name"]])
		n["effect"].position = Vector2(PAD, NODE_H - 2)
		n["effect"].size = Vector2(COL_W - 2 * PAD, NODE_H - 4)
		n["effect"].horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		UI.fit(n["effect"], [nd["words"], _short(nd["words"])])
		_style(btn, "taken" if nd["words"] != "" else "locked")
		n["name"].add_theme_color_override("font_color", Pal.TEXT)
		n["effect"].add_theme_color_override("font_color", Pal.TEXT_2)


## A paper's words cut to the column: up to the last full stop that fits.
static func _short(words: String) -> String:
	var cut := words.rfind(".", words.length() - 2)
	return words.substr(0, cut + 1) if cut > 0 else words


func _on_swap() -> void:
	mid += 1
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
	var out: Array = [_title, _words, _points, _past, _respec]
	if _ascend.visible:
		out.append(_ascend)
	if _swap.visible:
		out.append(_swap)
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
	return out
