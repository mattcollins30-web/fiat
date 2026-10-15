extends Control
## The crates (13 Oct, Matt; docs/design/search_crates.md; moved 14 Oct, mockups search_mockup3/4): a cleared site's
## search, in the run screen's left column under the six, where the rig and the take sit in a fight. The head folds the
## take in (open, tins, the pack); the row of crates in the dice's order - the open ones in their open art, the one
## being opened under the magnifier, its searches as pips, the rest as "+N more"; then the floor, a ? under the
## magnifier for the search in hand. The search's bar is the frame's (run.gd: it takes the HP bar's place till a gang
## comes). The Kennel's top rank noses the shut ones: each wears its best find's rarity.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Items := preload("res://scripts/sim/items.gd")

const SHOWN := 5                   # tiles in the row: past five, the last says how many more
const TILE_GAP := 8
const TILE_H := 70
const ART := 32
const ROW_Y := UI.HEAD_H + 2
const FINDS_HEAD_Y := ROW_Y + TILE_H + 4
const FINDS_Y := FINDS_HEAD_Y + UI.HEAD_H + 2
const ARROW := 44
const PAGE_W := 56
const HEIGHT := FINDS_Y + Pal.CELL    # 190
const WORDS := ["no", "one", "two", "three", "four", "five", "six"]
## A crate's colour until its art is painted (art/crates/<key>.png, <key>_open.png).
const TINT := {"cardboard": Color("b08a5a"), "ammo_tin": Color("7d8c4a"), "jewellery": Color("c9a0c8"), "toolbox": Color("b4483c"),
	"medicine": Color("d8dde2"), "filing": Color("8f9aa6"), "safe": Color("6b7178"), "military": Color("5f7a45")}

signal floor_picked(id: int)       # a thing on the floor pressed: its comparison (13 Oct, the floor)
signal floor_take(id: int)         # double-clicked: into the pack

var _head: Label
var _aside: Label
var _tiles: Array = []             # {panel, art, name, pips, glass, lock}
var _more: Panel                   # "+3 more" in the last tile's place
var _more_n: Label
var _finds_head: Label
var _cells: Array = []
var _query: Panel                  # the ? under the magnifier
var _query_mark: Label
var _query_glass: TextureRect
var _floor_ids: Array = []         # the ids in the row's cells, -1 for none
var _page := 0
var _prev: Button
var _next_page: Button
var _page_label: Label
var _press_at := Vector2.ZERO
var _press_cell := -1
var _floor_items := {}             # id -> the thing, for the drag's picture
var _w := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Cells across the row: all of it, or what's left beside the pages' arrows.
func cells_fit(paged: bool) -> int:
	var room: float = _w - (float(2 * ARROW + PAGE_W + 16) if paged else 0.0)
	return maxi(1, int((room + 8) / (Pal.CELL + 8)))


func build(w: float) -> void:
	_w = w
	size = Vector2(w, HEIGHT)
	_head = UI.head(self, Rect2(0, 0, w * 0.66, UI.HEAD_H), "The crates")
	_aside = UI.label(self, Rect2(w * 0.66, 0, w * 0.34, UI.HEAD_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var tw: float = (w - TILE_GAP * (SHOWN - 1)) / SHOWN
	for k in range(SHOWN):
		var p := UI.panel(self, Rect2(k * (tw + TILE_GAP), ROW_Y, tw, TILE_H), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE      # before the size: a texture's own size is its floor otherwise
		art.position = Vector2((tw - ART) / 2.0, 2)
		art.size = Vector2(ART, ART)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(art)
		var glass := TextureRect.new()
		glass.texture = NodeGlyphs.texture("search")
		glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glass.position = Vector2(tw - 26, 3)
		glass.size = Vector2(22, 22)
		glass.modulate = Pal.ACCENT
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(glass)
		var lock := TextureRect.new()
		lock.texture = NodeGlyphs.texture("lock")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.position = Vector2(4, 3)
		lock.size = Vector2(20, 20)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(lock)
		var nm := UI.label(p, Rect2(4, ART + 1, tw - 8, 18), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
		var pips := UI.label(p, Rect2(4, TILE_H - 23, tw - 8, 23), "", "SemiBold", 11, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		pips.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_tiles.append({"panel": p, "art": art, "name": nm, "pips": pips, "glass": glass, "lock": lock})
	_more = UI.panel(self, Rect2((SHOWN - 1) * (tw + TILE_GAP), ROW_Y, tw, TILE_H), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
	_more_n = UI.label(_more, Rect2(0, 6, tw, 36), "", "SemiBold", 28, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.label(_more, Rect2(0, 42, tw, 20), "more", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
	_more.visible = false
	_finds_head = UI.head(self, Rect2(0, FINDS_HEAD_Y, w, UI.HEAD_H), "")
	for k in range(cells_fit(false)):
		var c := ItemCell.new()
		c.position = Vector2(k * (Pal.CELL + 8), FINDS_Y)
		c.visible = false
		c.gui_input.connect(_cell_input.bind(k))
		add_child(c)
		_cells.append(c)
		_floor_ids.append(-1)
	# the floor's pages: past a row, the arrows at the row's end
	_prev = UI.button(self, Rect2(w - 2 * ARROW - 8, FINDS_Y + 10, ARROW, ARROW), false)
	_prev.text = "‹"
	_prev.pressed.connect(func(): _page = maxi(0, _page - 1); _shown_sig = "")
	_next_page = UI.button(self, Rect2(w - ARROW, FINDS_Y + 10, ARROW, ARROW), false)
	_next_page.text = "›"
	_next_page.pressed.connect(func(): _page += 1; _shown_sig = "")
	_page_label = UI.label(self, Rect2(w - 2 * ARROW - 8 - PAGE_W - 4, FINDS_Y + 10, PAGE_W, ARROW), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
	_query = UI.panel(self, Rect2(0, FINDS_Y, Pal.CELL, Pal.CELL), UI.box(Pal.BG, 6, 2, Pal.ACCENT))
	_query_mark = UI.label(_query, Rect2(0, 0, Pal.CELL * 0.62, Pal.CELL), "?", "SemiBold", 30, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER)
	_query_glass = TextureRect.new()
	_query_glass.texture = NodeGlyphs.texture("search")
	_query_glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_query_glass.position = Vector2(Pal.CELL - 32, 6)
	_query_glass.size = Vector2(26, 26)
	_query_glass.modulate = Pal.ACCENT
	_query.add_child(_query_glass)


## A warning over the head (HP low: the take's note is folded away with the crates up); "" for the head back.
func warn(text: String) -> void:
	if text != "":
		_head.text = text.to_upper()
		_head.add_theme_color_override("font_color", Pal.BAD)
	else:
		_head.add_theme_color_override("font_color", Pal.TEXT_3)


## A crate's picture: its art if it's painted (open or shut), else the line glyph in the crate's colour.
static func crate_texture(key: String, open: bool) -> Array:
	for nm in (["crates/%s_open" % key, "crates/%s" % key] if open else ["crates/%s" % key]):
		var tex: Texture2D = UI.glyph_texture(nm)
		if tex != null:
			return [tex, Color.WHITE]
	return [NodeGlyphs.texture("crate"), TINT.get(key, Pal.TEXT_2)]


## What the dog smells in a shut crate: "something Rare", "a unique"; "" for nothing nosed.
static func nosed(q: Dictionary) -> String:
	if not q.has("held"):
		return ""
	var it: Dictionary = q["held"]["it"]
	if it.has("unique"):
		return "a unique"
	if it.has("set"):
		return "a set piece"
	return "something %s" % str(Data.RARITIES[clampi(int(it.get("rarity", 0)), 0, Data.RARITIES.size() - 1)]["name"])


## Locked crates without the Caretaker's Keys are passed over (13 Oct): they aren't the site's to open.
static func passed_over(sim, cs: Array, j: int, i: int) -> bool:
	return cs[j].get("passed", false) or (j > i and cs[j].get("locked", false) and not sim.has_keys())


## The next crate to open after the one in hand, past the locked ones; the queue's size for none.
static func next_index(sim, cs: Array, i: int) -> int:
	var nxt: int = i + 1
	while nxt < cs.size() and cs[nxt].get("locked", false) and not sim.has_keys():
		nxt += 1
	return nxt


## "a cardboard box", "an ammo tin", "a locked safe".
static func crate_words(q: Dictionary) -> String:
	var nm: String = ("locked " if q.get("locked", false) else "") + str(q["name"]).to_lower()
	return ("an " if nm[0] in "aeiou" else "a ") + nm


## "2 finds", "1 find", "nothing".
static func finds_words(n: int) -> String:
	return "nothing" if n == 0 else ("1 find" if n == 1 else "%d finds" % n)


## The frame's search bar (14 Oct, Matt: it takes the HP bar's place while searching): [fill, words long to short,
## tone]. `opened` (run_view.opened()): the crate just opened, named for its moment.
static func bar_forms(sim, m: Dictionary, opened: Dictionary = {}) -> Array:
	var t: Dictionary = m["t"]
	var fill: float = clampf(float(m["search"]) / maxf(0.01, sim.search_s(t)), 0.0, 1.0)
	if not m.has("crates") or m.get("crates_off", false):
		return [fill, ["Searching"], ""]
	var done: bool = sim.crates_done(m)
	if not opened.is_empty():
		# the one just opened, named for its moment - the last one too, before picked clean (the review)
		var where: String = "on the floor" if sim.by_hand(m) else "into the pack"
		var f: String = finds_words(int(opened["finds"]))
		var after: String = "picked clean" if done else ("now: " + crate_words(sim.crate_now(m)))
		var short: String = "picked clean" if done else ("now: " + str(sim.crate_now(m)["name"]).to_lower())
		return [1.0 if done else fill, ["%s opened · %s %s · %s" % [opened["name"], f, where, after], "%s opened · %s · %s" % [opened["name"], f, short],
			"%s opened · %s" % [opened["name"], f]], ""]
	if done:
		return [1.0, ["Picked clean: every crate open", "Picked clean"], "warn"]     # the amber of the search otherwise ("")
	var cs: Array = m["crates"]
	var i: int = int(m.get("crate_i", 0))
	var q: Dictionary = cs[i]
	var now: String = str(q["name"])
	var nxt: int = next_index(sim, cs, i)
	var then: String = crate_words(cs[nxt]) if nxt < cs.size() else "the last crate"
	var search: String = "%s · search %d of %d" % [now, int(q["done"]) + 1, int(q["searches"])]
	return [fill, [search + " · next: " + then, search], ""]


func show_crates(sim, m: Dictionary) -> void:
	var cs: Array = m.get("crates", [])
	var i: int = int(m.get("crate_i", 0))
	var n: int = cs.size()
	var all_open: bool = i >= n
	var gang_on: bool = int(m["remaining"]) > 0
	var sniffs: bool = sim.dog_sniffs()
	var shut := 0
	var opened_n := 0
	for j in range(n):
		if passed_over(sim, cs, j, i):
			shut += 1                          # passed over, or will be (the Keys may come off or go on mid-run: the sim's mark first)
		elif j < i:
			opened_n += 1
	# the head: the take folded in (14 Oct, the take's tiles give the column to the crates while they're up)
	var locked_tail: String = (" · %d LOCKED" % shut) if shut > 0 else ""
	var opens: String = ("ALL %d OPEN" % (n - shut)) if all_open else ("%d OF %d OPEN" % [opened_n, n - shut])
	var tins: String = Fmt.money(m["cash"]).to_upper()
	var pack: String = "PACK %d OF %d" % [sim.pack_used(m), sim.capacity()]
	UI.fit(_head, ["THE CRATES · %s%s · %s · %s" % [opens, locked_tail, tins, pack], "%s%s · %s · %s" % [opens, locked_tail, tins, pack],
		"%s%s · %s" % [opens, locked_tail, pack], opens + locked_tail])
	_aside.text = "the dog's nose on them" if sniffs else "the dice's order"
	UI.fit(_aside, [_aside.text, "the dog's nose" if sniffs else "the dice's"])
	# the row: a window on the queue from the one opened last, the rest as "+N more"
	var start: int = clampi(i - 1, 0, maxi(0, n - SHOWN))
	var more: int = n - start - SHOWN + 1 if n - start > SHOWN else 0
	_more.visible = more > 0
	_more_n.text = "+%d" % more
	for k in range(SHOWN):
		var t: Dictionary = _tiles[k]
		var j: int = start + k
		t["panel"].visible = j < n and not (more > 0 and k == SHOWN - 1)
		if not t["panel"].visible:
			continue
		var q: Dictionary = cs[j]
		var c: Dictionary = sim.crate_def(str(q["key"]))
		var passed: bool = passed_over(sim, cs, j, i)
		var opened: bool = j < i and not passed
		var current: bool = j == i
		var pic: Array = crate_texture(str(q["key"]), opened)
		t["art"].texture = pic[0]
		t["art"].modulate = Color(pic[1], 0.3 if passed else (0.6 if opened else 1.0))
		t["lock"].visible = q.get("locked", false)       # locked: grey and passed over, or amber for the Keys to open
		t["lock"].modulate = Pal.TEXT_3 if passed else Pal.ACCENT
		t["glass"].visible = current
		UI.fit(t["name"], [str(c["name"]), str(c.get("short", c["name"]))])
		t["name"].add_theme_color_override("font_color", Pal.TEXT if current else (Pal.TEXT_3 if opened or passed else Pal.TEXT_2))
		var pips := ""
		for s in range(0 if passed else int(q["searches"])):
			pips += "●" if s < int(q["done"]) else "○"
		t["pips"].text = "opened" if opened else ("passed over" if passed else pips)
		t["pips"].add_theme_color_override("font_color", Pal.GOOD if opened else Pal.TEXT_3)
		var edge: Color = Pal.ACCENT if current else Pal.CARD_LINE
		var held: String = nosed(q) if (sniffs and not opened) else ""
		if held != "" and not current:
			edge = Pal.tone_color(Pal.item_tone(q["held"]["it"]))      # the dog's nose: the best find's rarity on the shut crate
		(t["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = edge
		(t["panel"].get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2 if (current or held != "") else 1)
	var searching_now: bool = not all_open and not gang_on
	var by_hand: bool = sim.by_hand(m)
	var finds: Array = []
	var full: bool = sim.pack_used(m) >= sim.capacity()
	if by_hand:
		# the floor (13 Oct, Matt): everything the site's given, newest first, for the taking; left behind when you go
		finds = sim.floor_items().duplicate()
		finds.reverse()
		var th: String = _things(finds.size())
		UI.fit(_finds_head, (["ON THE FLOOR · %s · PACK FULL: DITCH TO TAKE FROM IT" % th, "ON THE FLOOR · %s · PACK FULL" % th] if full and not finds.is_empty() else []) +
			["ON THE FLOOR · %s · DRAG TO THE PACK, OR DOUBLE-CLICK" % th, "ON THE FLOOR · %s · DRAG TO THE PACK" % th, "ON THE FLOOR · %s" % th])
	else:
		# the auto-run, "Fill up, then go", away: straight into the pack; the row shows the crate last searched
		var shown_i: int = i if (not all_open and int(cs[i]["done"]) > 0) else i - 1
		while shown_i >= 0 and cs[shown_i].get("passed", false):
			shown_i -= 1                   # a locked one passed over gave nothing
		finds = cs[shown_i]["finds"] if shown_i >= 0 and shown_i < n else []
		var nm: String = str(cs[shown_i]["name"]).to_upper() if shown_i >= 0 and shown_i < n else ""
		UI.fit(_finds_head, ["STRAIGHT INTO THE PACK · OUT OF THE %s" % nm, "STRAIGHT INTO THE PACK"] if nm != "" else ["STRAIGHT INTO THE PACK"])
	var q_n: int = 1 if searching_now else 0
	var paged: bool = by_hand and finds.size() + q_n > cells_fit(false)
	var room: int = maxi(1, cells_fit(paged) - q_n)
	var pages: int = maxi(1, ceili(float(finds.size()) / float(room)))
	_page = clampi(_page, 0, pages - 1) if by_hand else 0
	var from: int = _page * room if by_hand else maxi(0, finds.size() - room)
	_prev.visible = paged
	_next_page.visible = paged
	_page_label.visible = paged
	_prev.disabled = _page == 0
	_next_page.disabled = _page >= pages - 1
	_page_label.text = "%d / %d" % [_page + 1, pages]
	var sig: String = "%d|%d|%s|%d|%d|%d|%d" % [from, room, str(by_hand), finds.size(), finds.map(func(x_in): return [int(x_in["id"]), Items.stack_size(x_in)]).hash(), sim.equipped.hash(), sim.level()]     # the counts and the arrows too (the review); the locks as the level comes
	var x: float = 0.0
	_floor_items = {}
	for k in range(_cells.size()):
		var c = _cells[k]
		var f: int = from + k
		c.visible = f < finds.size() and k < room
		_floor_ids[k] = int(finds[f]["id"]) if c.visible and by_hand else -1
		c.mouse_filter = Control.MOUSE_FILTER_STOP if _floor_ids[k] >= 0 else Control.MOUSE_FILTER_IGNORE
		if c.visible:
			if sig != _shown_sig:
				c.show_item(finds[f], false, Vector2(Pal.CELL, Pal.CELL))
				if by_hand:
					c.set_upgrade(sim.is_upgrade(finds[f]))     # the arrow: better than what's worn
					c.set_locked(sim.wear_lock(finds[f]))       # or the padlock: over the runner's level (15 Oct)
			c.position.x = x
			x += Pal.CELL + 8
			if by_hand:
				_floor_items[int(finds[f]["id"])] = finds[f]
	_shown_sig = sig
	_query.visible = searching_now
	_query.position.x = x


var _shown_sig := ""
var _click_token := 0
const DOUBLE_S := 0.3


static func _things(n: int) -> String:
	return "NOTHING YET" if n == 0 else ("1 THING" if n == 1 else "%d THINGS" % n)


## A floor cell: a press and a move is a drag to the pack, a double-click takes it, a click shows its comparison.
func _cell_input(event: InputEvent, k: int) -> void:
	var id: int = _floor_ids[k]
	if id < 0:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click:
			_press_cell = -1
			_click_token += 1                  # the click waiting to show the comparison is the double-click's
			floor_take.emit(id)
		elif event.pressed:
			_press_at = event.position
			_press_cell = k
		elif _press_cell == k:
			_press_cell = -1
			# a click shows the comparison - once it's plain it wasn't the first of a double-click
			_click_token += 1
			var token: int = _click_token
			if is_inside_tree():
				get_tree().create_timer(DOUBLE_S).timeout.connect(func(): if token == _click_token: floor_picked.emit(id))
			else:
				floor_picked.emit(id)
	elif event is InputEventMouseMotion and _press_cell == k and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) and event.position.distance_to(_press_at) > 10.0:
		_press_cell = -1
		_cells[k].force_drag({"id": id, "src": "floor"}, Inventory.drag_preview(_floor_items.get(id, {})))


func text_nodes() -> Array:
	var out: Array = [_head, _aside, _finds_head]
	for t in _tiles:
		if t["panel"].visible:
			out.append_array([t["name"], t["pips"]])
	if _more.visible:
		out.append(_more_n)
	for c in _cells:
		if c.visible:
			out.append_array(c.text_nodes())
	for b in [_prev, _next_page]:
		if b.visible:
			out.append(b)
	if _page_label.visible:
		out.append(_page_label)
	return out
