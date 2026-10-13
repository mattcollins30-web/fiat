extends Panel
## The crates (13 Oct, Matt; docs/design/search_crates.md, mockup B): a cleared site's search, on the run screen's
## right under the pack. The row of crates in the dice's order - the open ones ticked, the one being opened under the
## magnifier, its searches as pips - then what came out of the last one searched, a ? under the magnifier for the
## search in hand, the search's bar, and a line on what's next and when the next gang's due. The Kennel's top rank
## noses the shut ones: each wears its best find's rarity.

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Fmt := preload("res://scripts/ui/fmt.gd")
const Data := preload("res://scripts/sim/data.gd")
const ItemCell := preload("res://scripts/ui/item_cell.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const Inventory := preload("res://scripts/ui/inventory.gd")
const Items := preload("res://scripts/sim/items.gd")

const PAD := 18
const SHOWN := 7                   # crates in the row at once: a long queue slides along it
const TILE_GAP := 8
const TILE_H := 96
const ART := 52
const ROW_Y := 40
const FINDS_HEAD_Y := ROW_Y + TILE_H + 8
const FINDS_Y := FINDS_HEAD_Y + 24
const FINDS_MAX := 9               # cells in the floor's row, the ? among them; the pages' arrows past them
const ARROW := 44
const BAR_Y := FINDS_Y + Pal.CELL + 8
const BAR_H := 24
const NEXT_Y := BAR_Y + BAR_H + 4
const HEIGHT := NEXT_Y + 30 + 6    # 304: the pick panel's room
const WORDS := ["no", "one", "two", "three", "four", "five", "six"]
## A crate's colour until its art is painted (art/crates/<key>.png, <key>_open.png).
const TINT := {"cardboard": Color("b08a5a"), "ammo_tin": Color("7d8c4a"), "jewellery": Color("c9a0c8"), "toolbox": Color("b4483c"),
	"medicine": Color("d8dde2"), "filing": Color("8f9aa6"), "safe": Color("6b7178"), "military": Color("5f7a45")}

signal toggled                     # the bar pressed: back to the pick (13 Oct, Matt: one search bar at a time)
signal floor_picked(id: int)       # a thing on the floor pressed: its comparison (13 Oct, the floor)
signal floor_take(id: int)         # double-clicked: into the pack

var _head: Label
var _aside: Label
var _tiles: Array = []             # {panel, art, name, pips, tick, glass, lock}
var _finds_head: Label
var _cells: Array = []
var _query: Panel                  # the ? under the magnifier
var _query_mark: Label
var _query_glass: TextureRect
var _track: Panel
var _fill: Panel
var _bar_text: Label
var _next: Label
var _bar_button: Button
var _floor_ids: Array = []         # the ids in the row's cells, -1 for none
var _page := 0
var _prev: Button
var _next_page: Button
var _page_label: Label
var _press_at := Vector2.ZERO
var _press_cell := -1
var _floor_items := {}             # id -> the thing, for the drag's picture


func _init() -> void:
	add_theme_stylebox_override("panel", UI.box(Pal.CARD, 8, 1, Pal.CARD_LINE))
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func build(w: float, h: float = HEIGHT) -> void:
	size = Vector2(w, maxf(h, HEIGHT))
	var inner: float = w - 2 * PAD
	_head = UI.head(self, Rect2(PAD, 10, inner * 0.6, UI.HEAD_H), "The crates")
	_aside = UI.label(self, Rect2(PAD + inner * 0.6, 10, inner * 0.4, UI.HEAD_H), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT, false)
	var tw: float = (inner - TILE_GAP * (SHOWN - 1)) / SHOWN
	for k in range(SHOWN):
		var p := UI.panel(self, Rect2(PAD + k * (tw + TILE_GAP), ROW_Y, tw, TILE_H), UI.box(Pal.BG, 6, 1, Pal.CARD_LINE))
		var art := TextureRect.new()
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE      # before the size: a texture's own size is its floor otherwise
		art.position = Vector2((tw - ART) / 2.0, 6)
		art.size = Vector2(ART, ART)
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(art)
		var tick := UI.label(p, Rect2(0, 6, tw, ART), "✓", "SemiBold", 34, Pal.GOOD, HORIZONTAL_ALIGNMENT_CENTER)
		var glass := TextureRect.new()
		glass.texture = NodeGlyphs.texture("search")
		glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		glass.position = Vector2(tw - 32, 4)
		glass.size = Vector2(28, 28)
		glass.modulate = Pal.ACCENT
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(glass)
		var lock := TextureRect.new()
		lock.texture = NodeGlyphs.texture("lock")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.position = Vector2(4, 4)
		lock.size = Vector2(24, 24)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(lock)
		var name := UI.label(p, Rect2(4, ART + 2, tw - 8, 20), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
		var pips := UI.label(p, Rect2(4, TILE_H - 25, tw - 8, 23), "", "SemiBold", 12, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_CENTER, false)
		_tiles.append({"panel": p, "art": art, "name": name, "pips": pips, "tick": tick, "glass": glass, "lock": lock})
	_finds_head = UI.head(self, Rect2(PAD, FINDS_HEAD_Y, inner, UI.HEAD_H), "")
	for k in range(FINDS_MAX):
		var c := ItemCell.new()
		c.position = Vector2(PAD + k * (Pal.CELL + 8), FINDS_Y)
		c.visible = false
		c.gui_input.connect(_cell_input.bind(k))
		add_child(c)
		_cells.append(c)
		_floor_ids.append(-1)
	# the floor's pages: past ten things, the arrows at the row's end
	_prev = UI.button(self, Rect2(PAD + inner - 2 * ARROW - 8, FINDS_Y + 10, ARROW, ARROW), false)
	_prev.text = "‹"
	_prev.pressed.connect(func(): _page = maxi(0, _page - 1); _shown_sig = "")
	_next_page = UI.button(self, Rect2(PAD + inner - ARROW, FINDS_Y + 10, ARROW, ARROW), false)
	_next_page.text = "›"
	_next_page.pressed.connect(func(): _page += 1; _shown_sig = "")
	_page_label = UI.label(self, Rect2(PAD + inner - 2 * ARROW - 8 - 64, FINDS_Y + 10, 60, ARROW), "", "Regular", Pal.CELL_TEXT, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_RIGHT)
	_query = UI.panel(self, Rect2(PAD, FINDS_Y, Pal.CELL, Pal.CELL), UI.box(Pal.BG, 6, 2, Pal.ACCENT))
	_query_mark = UI.label(_query, Rect2(0, 0, Pal.CELL * 0.62, Pal.CELL), "?", "SemiBold", 30, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER)
	_query_glass = TextureRect.new()
	_query_glass.texture = NodeGlyphs.texture("search")
	_query_glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_query_glass.position = Vector2(Pal.CELL - 32, 6)
	_query_glass.size = Vector2(26, 26)
	_query_glass.modulate = Pal.ACCENT
	_query.add_child(_query_glass)
	_track = UI.panel(self, Rect2(PAD, BAR_Y, inner, BAR_H), UI.box(Pal.BG, 6))
	_fill = UI.panel(_track, Rect2(0, 0, 0, BAR_H), UI.box(Pal.ACCENT, 6))
	_bar_text = UI.label(_track, Rect2(0, 0, inner, BAR_H), "", "SemiBold", Pal.CELL_TEXT, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER, false)
	UI.shadow(_bar_text)
	var b := Button.new()
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	b.position = _track.position
	b.size = _track.size
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.tooltip_text = "Back to the pick"
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", UI.box(Color(1, 1, 1, 0.06), 6))
	b.add_theme_stylebox_override("pressed", UI.box(Color(1, 1, 1, 0.1), 6))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.pressed.connect(func(): toggled.emit())
	add_child(b)
	_bar_button = b
	_next = UI.label(self, Rect2(PAD, NEXT_Y, inner, 30), "", "Regular", Pal.CELL_TEXT_BIG, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)


## A crate's picture: its art if it's painted (open or shut), else the line glyph in the crate's colour.
static func crate_texture(key: String, open: bool) -> Array:
	for name in (["crates/%s_open" % key, "crates/%s" % key] if open else ["crates/%s" % key]):
		var tex: Texture2D = UI.glyph_texture(name)
		if tex != null:
			return [tex, Color.WHITE]
	return [NodeGlyphs.texture("crate"), TINT.get(key, Pal.TEXT_2)]


## "four searches", "one search".
static func searches_words(n: int) -> String:
	return "%s search%s" % [WORDS[n] if n < WORDS.size() else str(n), "" if n == 1 else "es"]


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


func show_crates(sim, m: Dictionary) -> void:
	var cs: Array = m.get("crates", [])
	var i: int = int(m.get("crate_i", 0))
	var n: int = cs.size()
	var all_open: bool = i >= n
	var gang_on: bool = int(m["remaining"]) > 0
	var sniffs: bool = sim.dog_sniffs()
	var keys: bool = sim.has_keys()
	# a locked crate without the Caretaker's Keys is passed over (13 Oct): it isn't one of the site's to open
	var shut := 0
	var opened_n := 0
	for j in range(n):
		if cs[j].get("passed", false) or (j > i and cs[j].get("locked", false) and not keys):
			shut += 1                          # passed over, or will be (the Keys may come off or go on mid-run: the sim's mark first)
		elif j < i:
			opened_n += 1
	var locked_tail: String = (" · %d LOCKED" % shut) if shut > 0 else ""
	_head.text = (("THE CRATES · ALL %d OPEN" % (n - shut)) if all_open else ("THE CRATES · %d OF %d OPEN" % [opened_n, n - shut])) + locked_tail
	_aside.text = "the dog's nose on them" if sniffs else "the order's the dice's"
	# the row: a window on the queue, the one being opened kept in it
	var start: int = clampi(i - 2, 0, maxi(0, n - SHOWN))
	for k in range(SHOWN):
		var t: Dictionary = _tiles[k]
		var j: int = start + k
		t["panel"].visible = j < n
		if j >= n:
			continue
		var q: Dictionary = cs[j]
		var c: Dictionary = sim.crate_def(str(q["key"]))
		var passed: bool = q.get("passed", false) or (j > i and q.get("locked", false) and not keys)     # passed over, or it will be
		var opened: bool = j < i and not passed
		var current: bool = j == i
		var pic: Array = crate_texture(str(q["key"]), opened)
		t["art"].texture = pic[0]
		t["art"].modulate = Color(pic[1], 0.3 if passed else (0.45 if opened else 1.0))
		t["tick"].visible = opened
		t["lock"].visible = q.get("locked", false)       # locked: grey and passed over, or amber for the Keys to open
		t["lock"].modulate = Pal.TEXT_3 if passed else Pal.ACCENT
		t["glass"].visible = current
		UI.fit(t["name"], [str(c["name"]), str(c.get("short", c["name"]))])
		t["name"].add_theme_color_override("font_color", Pal.TEXT if current else Pal.TEXT_2)
		var pips := ""
		for s in range(0 if passed else int(q["searches"])):
			pips += "●" if s < int(q["done"]) else "○"
		t["pips"].text = pips
		var edge: Color = Pal.ACCENT if current else Pal.CARD_LINE
		var held: String = nosed(q) if (sniffs and not opened) else ""
		if held != "" and not current:
			edge = Pal.tone_color(Pal.item_tone(q["held"]["it"]))      # the dog's nose: the best find's rarity on the shut crate
		(t["panel"].get_theme_stylebox("panel") as StyleBoxFlat).border_color = edge
		(t["panel"].get_theme_stylebox("panel") as StyleBoxFlat).set_border_width_all(2 if (current or held != "") else 1)
	var searching_now: bool = not all_open and not gang_on
	var by_hand: bool = sim.by_hand(m)
	var finds: Array = []
	if by_hand:
		# the floor (13 Oct, Matt): everything the site's given, newest first, for the taking; left behind when you go
		finds = sim.floor_items().duplicate()
		finds.reverse()
		UI.fit(_finds_head, ["ON THE FLOOR · %s · DRAG TO THE PACK, OR DOUBLE-CLICK · LEFT BEHIND WHEN YOU GO" % _things(finds.size()),
			"ON THE FLOOR · %s · DRAG TO THE PACK, OR DOUBLE-CLICK" % _things(finds.size()), "ON THE FLOOR · %s" % _things(finds.size())])
	else:
		# the auto-run, "Fill up, then go", away: straight into the pack; the row shows the crate last searched
		var shown_i: int = i if (not all_open and int(cs[i]["done"]) > 0) else i - 1
		while shown_i >= 0 and cs[shown_i].get("passed", false):
			shown_i -= 1                   # a locked one passed over gave nothing
		finds = cs[shown_i]["finds"] if shown_i >= 0 and shown_i < n else []
		var nm: String = str(cs[shown_i]["name"]).to_upper() if shown_i >= 0 and shown_i < n else ""
		_finds_head.text = ("STRAIGHT INTO THE PACK · OUT OF THE %s" % nm) if nm != "" else "STRAIGHT INTO THE PACK"
	var room: int = FINDS_MAX - (1 if searching_now else 0)
	var pages: int = maxi(1, ceili(float(finds.size()) / float(room)))
	_page = clampi(_page, 0, pages - 1) if by_hand else 0
	var from: int = _page * room if by_hand else maxi(0, finds.size() - room)
	_prev.visible = by_hand and pages > 1
	_next_page.visible = by_hand and pages > 1
	_page_label.visible = by_hand and pages > 1
	_prev.disabled = _page == 0
	_next_page.disabled = _page >= pages - 1
	_page_label.text = "%d / %d" % [_page + 1, pages]
	var sig: String = "%d|%d|%s|%d|%d|%d" % [from, room, str(by_hand), finds.size(), finds.map(func(x): return [int(x["id"]), Items.stack_size(x)]).hash(), sim.equipped.hash()]     # the counts and the arrows too (the review)
	var x: float = PAD
	_floor_items = {}
	for k in range(FINDS_MAX):
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
			c.position.x = x
			x += Pal.CELL + 8
			if by_hand:
				_floor_items[int(finds[f]["id"])] = finds[f]
	_shown_sig = sig
	_query.visible = searching_now
	_query.position.x = x
	# the bar: the search in hand, or why it waits
	var every: float = sim.search_s(m["t"])
	var tone: Color = Pal.ACCENT
	if all_open:
		_fill.size.x = _track.size.x
		_bar_text.text = "Picked clean: every crate open · show the pick"
		tone = Pal.TEXT_3
	elif gang_on:
		_fill.size.x = _track.size.x * clampf(float(m["search"]) / every, 0.0, 1.0)
		_bar_text.text = "A gang's on you: the %s waits · show the pick" % str(cs[i]["name"]).to_lower()
		tone = Pal.BAD
	else:
		_fill.size.x = _track.size.x * clampf(float(m["search"]) / every, 0.0, 1.0)
		_bar_text.text = "%s · search %d of %d · show the pick" % [cs[i]["name"], int(cs[i]["done"]) + 1, int(cs[i]["searches"])]
	(_fill.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = tone
	# what's next, and the gang's clock: the stay-or-go call
	var gang: String = ""
	if not gang_on:
		var due: float = sim.patrol_s(m["t"], m["patrols"] == 0) - float(m["patrol_timer"])
		gang = " The next gang's on the call." if sim.gang_held(m) else ((" The next gang's due in %s." % Fmt.mss(due)) if due < 1e8 else "")
	var line := ""
	var nxt: int = i + 1
	while nxt < n and cs[nxt].get("locked", false) and not keys:
		nxt += 1                           # the next one opened, past the locked ones
	if all_open:
		line = "Nothing more here." if shut == 0 else "Nothing more here; the locked ones want the Caretaker's Keys."
	elif nxt >= n:
		line = "The last crate."
	else:
		var nx: Dictionary = cs[nxt]
		var smell: String = nosed(nx) if sniffs else ""
		var nm: String = ("locked " if nx.get("locked", false) else "") + str(nx["name"]).to_lower()
		line = "Next: %s %s, %s%s%s." % ["an" if nm[0] in "aeiou" else "a", nm, searches_words(int(nx["searches"])), (", " + smell + " inside") if smell != "" else "",
			", the Keys open it" if nx.get("locked", false) else ""]
	UI.fit(_next, [line + gang, line])


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
	var out: Array = [_head, _aside, _finds_head, _bar_text, _next]
	for t in _tiles:
		if t["panel"].visible:
			out.append(t["name"])
	for c in _cells:
		if c.visible:
			out.append_array(c.text_nodes())
	for b in [_prev, _next_page]:
		if b.visible:
			out.append(b)
	if _page_label.visible:
		out.append(_page_label)
	return out
