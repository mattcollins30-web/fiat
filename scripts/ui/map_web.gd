extends Control
## The Dial's tree as columns (28 Oct, the mockup RadioDial; Matt: "the Radio looks crap" - the web of 22 Oct was a
## small star in an empty canvas). The atlas's three regions (Data.MAP_WEB) side by side - the sites, the crews, the
## codes - each a column: its spine down the middle from the entry at the top to the keystone at the foot, its two
## branches either side, every node a named tile (its rank, or what it is: a node, notable, the keystone and the points
## it opens at), the fillers smaller between a branch's nodes. The links drawn under the tiles, lit where both ends are
## ranked. A tile pressed is picked: the Dial's panel under it says it and ranks it. The pathing is the sim's, as on the
## web: a tile open to a rank reads lit, a shut one dim.
##
## Signals: `picked(id)` with the tile's Map id ("The sites/3").

signal picked(id: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const WebView := preload("res://scripts/ui/web_view.gd")
const Items := preload("res://scripts/sim/items.gd")

const COL_GAP := 12
const CP := 10                      # a column's padding
const SUB_GAP := 8                  # between the left branch, the spine and the right branch
const HEAD_H := 46                  # a column's name and its points
const NODE_H := 48
const FILLER_H := 22
const FILLER_INSET := 14            # a filler narrower than a node, either side
const NAME_SIZES := [15, 14, 13]    # a long name steps down before it's cut (28 Oct: "The lie of the land" in a third of a column)
const LINK := Color("4a5059")       # the web's dim link (23 Oct: CARD_LINE was lost)
const LINK_W := 2.0
## Each node's picture on its box (BUILD49 U, item 14, layout A; Matt: "this reads as a placeholder - ... i thought we
## had art for these"): the picture at the box's left, the ranks a small badge on it; a notable's box a size up framed
## amber, a keystone's bigger again in gold, as the web frames them; a filler's picture its pill's mark.
const PIC := {"node": 40, "notable": 48, "keystone": 56}
const BOX_H := {"node": 48, "notable": 56, "keystone": 64}
const FILLER_PIC := 18
const GOLD := Pal.LEGENDARY
const BADGE_H := 15

var sim
var selected := ""                  # the picked tile's Map id
var layout := {}                    # id -> Rect2, in this control's space (the smoke reads it)
var col_rects: Array = []           # a region's column, by its order in Data.MAP_WEB
var _cols: Array = []               # {panel, name, pts, links, tree}
var _tiles := {}                    # id -> {button, name, line, filler, key}
var _shown := ""


## A link layer under a column's tiles: [from, to, colour] segments.
class Links extends Control:
	var segs: Array = []

	func _draw() -> void:
		for s in segs:
			draw_line(s[0], s[1], s[2], 2.0, true)


func _init(sz: Vector2) -> void:
	size = sz
	mouse_filter = Control.MOUSE_FILTER_PASS
	var n: int = Data.MAP_WEB.size()
	var cw: float = (sz.x - (n - 1) * COL_GAP) / n
	for c in range(n):
		var t: Dictionary = Data.MAP_WEB[c]
		var r := Rect2(c * (cw + COL_GAP), 0, cw, sz.y)
		col_rects.append(r)
		var p := UI.panel(self, r, UI.box(Pal.PANEL, 8, 1, Pal.CARD_LINE))
		var col := {"panel": p, "tree": t["name"]}
		col["name"] = UI.label(p, Rect2(16, 8, 150, 34), str(t["name"]), "SemiBold", Pal.FLOOR - 2, Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		col["pts"] = UI.label(p, Rect2(16, 8, cw - 32, 34), "", "Medium", Pal.CELL_TEXT - 1, Pal.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, false)
		var lk := Links.new()
		lk.size = r.size
		lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(lk)
		col["links"] = lk
		_cols.append(col)
		_lay_column(c, t, r)


## A region's tiles: the spine's four down the middle, entry at the top and keystone at the foot; each branch down its
## side in its path's order (a filler, a node, ... the filler into the keystone), spread over the same height so a
## branch leaves the entry's row and comes back in at the keystone's.
func _lay_column(c: int, t: Dictionary, r: Rect2) -> void:
	var sw: float = (r.size.x - 2 * CP - 2 * SUB_GAP) / 3.0
	var top: float = HEAD_H
	var bottom: float = r.size.y - CP
	var spine: Array = []
	var sides := {-1: [], 1: []}
	for i in range(t["nodes"].size()):
		var nd: Dictionary = t["nodes"][i]
		var y_off: float = float(nd["at"][1])
		if is_zero_approx(y_off):
			spine.append(i)
		else:
			sides[-1 if y_off < 0.0 else 1].append(i)
	var xs := {-1: CP, 0: CP + sw + SUB_GAP, 1: CP + 2 * (sw + SUB_GAP)}
	_lay_run(t, c, spine, xs[0], sw, top, bottom)
	# a branch's run starts and ends level with the entry's and the keystone's middles
	var inset: float = (NODE_H - FILLER_H) / 2.0
	var drop: float = (BOX_H["keystone"] - NODE_H) / 2.0     # the keystone's middle, a size up from a node's (item 14)
	for side in [-1, 1]:
		_lay_run(t, c, sides[side], xs[side], sw, top + inset, bottom - inset - drop)


## `ids` (indices into the tree's nodes) down from `y0` to `y1` at `x`, spread evenly.
func _lay_run(t: Dictionary, c: int, ids: Array, x: float, w: float, y0: float, y1: float) -> void:
	var total := 0.0
	for i in ids:
		total += _box_h(t["nodes"][i])
	var gap: float = (y1 - y0 - total) / maxf(1.0, ids.size() - 1)
	var y: float = y0
	for i in ids:
		var nd: Dictionary = t["nodes"][i]
		var filler: bool = nd.get("filler", false)
		var h: float = _box_h(nd)
		var inset: float = float(FILLER_INSET) if filler else 0.0
		var rect := Rect2(x + inset, y, w - 2.0 * inset, h)
		_make_tile("%s/%d" % [t["name"], i], nd, c, rect)
		y += h + gap


func _make_tile(id: String, nd: Dictionary, c: int, rect: Rect2) -> void:
	var p: Panel = _cols[c]["panel"]
	var b := Button.new()
	b.position = rect.position
	b.size = rect.size
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_press.bind(id))
	p.add_child(b)
	var filler: bool = nd.get("filler", false)
	var t := {"button": b, "filler": filler, "key": str(nd["key"])}
	var kind: String = kind_of(nd)
	t["kind"] = kind
	if filler:
		t["pic"] = _pic_rect(b, Rect2(8, (rect.size.y - FILLER_PIC) / 2.0, FILLER_PIC, FILLER_PIC))
		var fx: float = 8 + FILLER_PIC + 6
		t["name"] = UI.label(b, Rect2(fx, 0, rect.size.x - fx - 8, rect.size.y), "", "Medium", Pal.CELL_TEXT - 4, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_LEFT, false)
	else:
		var ps: float = PIC[kind]
		var pf := UI.panel(b, Rect2(4, (rect.size.y - ps) / 2.0, ps, ps), UI.box(Pal.BG, 4))
		pf.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t["pic"] = _pic_rect(pf, Rect2(0, 0, ps, ps))
		t["badge"] = UI.panel(pf, Rect2(ps - 30, ps - BADGE_H, 30, BADGE_H), UI.box(Color(Pal.BG, 0.85), 3))
		t["badge"].mouse_filter = Control.MOUSE_FILTER_IGNORE
		t["rank"] = UI.label(t["badge"], Rect2(0, 0, 30, BADGE_H), "", "SemiBold", 11, Pal.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
		var tx: float = 4 + ps + 8
		var tw: float = rect.size.x - tx - 6
		t["name"] = UI.label(b, Rect2(tx, 4, tw, 20), "", "SemiBold", NAME_SIZES[0], Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["name2"] = UI.label(b, Rect2(tx, 22, tw, 18), "", "SemiBold", NAME_SIZES[0], Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["line"] = UI.label(b, Rect2(tx, 25, tw, 18), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tiles[id] = t
	layout[id] = Rect2(p.position + rect.position, rect.size)


## A box's kind: "filler", "keystone", "notable" or "node".
static func kind_of(nd: Dictionary) -> String:
	if nd.get("filler", false):
		return "filler"
	var a: Dictionary = Data.atlas_of(str(nd.get("key", "")))
	return "keystone" if a.get("keystone", false) else ("notable" if a.get("notable", false) else "node")


static func _box_h(nd: Dictionary) -> float:
	var k: String = kind_of(nd)
	return float(FILLER_H) if k == "filler" else float(BOX_H[k])


## A node's picture (art/nodes/map_<key>.png; a filler's map_f_<name>), as the Dial's panel finds it.
static func picture_of(key: String) -> Texture2D:
	var a: Dictionary = Data.atlas_of(key)
	if a.is_empty():
		return null
	return WebView.picture(("map_f_" + Items.slug(str(a.get("name", "")))) if a.get("filler", false) else ("map_" + key))


func _pic_rect(parent: Control, r: Rect2) -> TextureRect:
	var pic := TextureRect.new()
	pic.position = r.position
	pic.size = r.size
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(pic)
	return pic


func _press(id: String) -> void:
	picked.emit(id)


func node_of(id: String) -> Dictionary:
	return Data.map_node(id)


## A tile's state, as the web's was: ranked, open to a rank, or shut and why.
func state_of(id: String) -> Dictionary:
	if sim == null:
		return {}
	var key: String = str(Data.map_node(id).get("key", ""))
	var rank: int = sim.atlas_rank(key)
	var top: int = int(Data.atlas_of(key)["max"])
	var block: String = sim.atlas_block(key, true)
	return {"taken": rank > 0, "reach": rank < top and block == "", "block": block, "rank": rank, "max": top}


## The points in a region, as its column's head says them.
func region_words(tn: String) -> String:
	for t in Data.MAP_WEB:
		if t["name"] == tn:
			var pts: int = sim.atlas_in_lane(int(t["column"]))
			return "%d point%s in" % [pts, "" if pts == 1 else "s"]
	return ""


func show_state(s) -> void:
	sim = s
	var sig := "%s|%d|%s|%s" % [str(sim.atlas), sim.atlas_points, selected, str(sim.on_mission())]
	if sig == _shown:
		return
	_shown = sig
	var states := {}
	for id in _tiles:
		states[id] = state_of(id)
	for c in range(_cols.size()):
		var col: Dictionary = _cols[c]
		var nl: Label = col["name"]
		nl.size.x = ceilf(UI.text_width(nl, nl.text)) + 4
		col["pts"].position.x = nl.position.x + nl.size.x + 12
		col["pts"].size.x = col["panel"].size.x - 16 - col["pts"].position.x
		UI.fit(col["pts"], [region_words(str(col["tree"])), ""])
	for id in _tiles:
		_show_tile(id, states[id])
	_draw_links(states)


func _show_tile(id: String, st: Dictionary) -> void:
	var t: Dictionary = _tiles[id]
	var a: Dictionary = Data.atlas_of(str(t["key"]))
	var taken: bool = st["taken"]
	var reach: bool = st["reach"]
	var on: bool = id == selected
	var kind: String = str(t["kind"])
	var frame: Color = GOLD if kind == "keystone" else (Pal.ACCENT if kind == "notable" else Color.TRANSPARENT)
	var edge: Color = Pal.TEXT if on else (frame if frame.a > 0.0 else (Pal.ACCENT if taken else (Pal.TEXT_3 if reach else Pal.CARD_LINE)))
	if frame.a > 0.0 and not on and not taken and not reach:
		edge = Color(frame, 0.6)                 # a big node shut: its frame dimmed, still its colour
	var ground: Color = Pal.CARD.blend(Color(Pal.ACCENT, 0.12)) if taken else (Pal.CARD if reach else Pal.BG)
	var bw: int = 2 if (on or taken or frame.a > 0.0) else 1
	var b: Button = t["button"]
	b.add_theme_stylebox_override("normal", UI.box(ground, 6, bw, edge))
	b.add_theme_stylebox_override("hover", UI.box(Pal.BUTTON, 6, bw, edge))
	b.add_theme_stylebox_override("pressed", UI.box(Pal.BUTTON_PRESS, 6, bw, edge))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))
	b.tooltip_text = str(a.get("words", ""))
	var nm: String = str(a.get("name", ""))
	var lit: Color = Pal.TEXT if (taken or reach) else Pal.TEXT_2
	t["pic"].texture = picture_of(str(t["key"]))
	t["pic"].modulate = Color.WHITE if (taken or reach) else Color(1, 1, 1, 0.55)
	if t["filler"]:
		_fit_name(t["name"], nm, [Pal.CELL_TEXT - 4, Pal.CELL_TEXT - 5])
		t["name"].add_theme_color_override("font_color", Pal.ACCENT if taken else lit)
		return
	var top: int = int(st["max"])
	t["badge"].visible = top > 1
	t["rank"].text = "%d/%d" % [int(st["rank"]), top] if top > 1 else ""
	t["rank"].add_theme_color_override("font_color", Pal.ACCENT if taken else Pal.TEXT)
	var line: Array = []
	if kind == "keystone":
		line = ["keystone · %d in" % Data.MAP_KEYSTONE_POINTS, "keystone"]
	elif kind == "notable":
		line = ["notable"]
	var bh: float = b.size.y
	var two: bool = _fit_name2(t["name"], t["name2"], nm, NAME_SIZES)
	var rows: int = (2 if two else 1) + (1 if not line.is_empty() else 0)
	var y: float = (bh - rows * 17.0) / 2.0 - 1.0
	t["name"].position.y = y
	t["name"].size.y = 18
	t["name2"].position.y = y + 16
	t["name2"].size.y = 18
	t["line"].position.y = y + (32 if two else 16)
	t["line"].visible = not line.is_empty()
	if not line.is_empty():
		UI.fit(t["line"], line)
	t["name"].add_theme_color_override("font_color", lit)
	t["name2"].add_theme_color_override("font_color", lit)
	t["line"].add_theme_color_override("font_color", GOLD if kind == "keystone" else Pal.ACCENT)


## A name on one line at the first of `sizes` it fits at, else over two lines (split at a word) at the first size both
## halves fit; past that, one line shortened. Returns whether it took two lines.
func _fit_name2(l: Label, l2: Label, nm: String, sizes: Array) -> bool:
	for sz in sizes:
		l.add_theme_font_size_override("font_size", int(sz))
		if UI.text_width(l, nm) <= l.size.x:
			l.text = nm
			l2.text = ""
			return false
	var words: PackedStringArray = nm.split(" ")
	for sz in sizes:
		l.add_theme_font_size_override("font_size", int(sz))
		l2.add_theme_font_size_override("font_size", int(sz))
		for cut in range(words.size() - 1, 0, -1):
			var a: String = " ".join(words.slice(0, cut))
			var b2: String = " ".join(words.slice(cut))
			if UI.text_width(l, a) <= l.size.x and UI.text_width(l2, b2) <= l2.size.x:
				l.text = a
				l2.text = b2
				return true
	l2.text = ""
	UI.fit(l, [nm, nm.trim_prefix("The ")])
	return false


## A name at the first of `sizes` it fits at; past the last, its shorter forms.
func _fit_name(l: Label, nm: String, sizes: Array) -> void:
	for sz in sizes:
		l.add_theme_font_size_override("font_size", int(sz))
		if UI.text_width(l, nm) <= l.size.x:
			l.text = nm
			return
	UI.fit(l, [nm, nm.trim_prefix("The ")])


## The links under the tiles, from middle to middle: lit where both ends are ranked, half where one is.
func _draw_links(states: Dictionary) -> void:
	var links: Dictionary = Data.map_links()
	for col in _cols:
		var segs: Array = []
		var p: Panel = col["panel"]
		for a in links:
			if str(a).get_slice("/", 0) != str(col["tree"]):
				continue
			for b in links[a]:
				if str(a) > str(b) or not layout.has(a) or not layout.has(b):
					continue
				var ta: bool = states[a]["taken"]
				var tb: bool = states[b]["taken"]
				var colour: Color = Pal.ACCENT if (ta and tb) else (Color(Pal.ACCENT, 0.5) if (ta or tb) else LINK)
				segs.append([layout[a].get_center() - p.position, layout[b].get_center() - p.position, colour])
		col["links"].segs = segs
		col["links"].queue_redraw()


func text_nodes() -> Array:
	var out: Array = []
	for col in _cols:
		out.append_array([col["name"], col["pts"]])
	for id in _tiles:
		out.append(_tiles[id]["name"])
		for k in ["name2", "line", "rank"]:
			if _tiles[id].has(k) and _tiles[id][k].visible:
				out.append(_tiles[id][k])
	return out
