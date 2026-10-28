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
	for side in [-1, 1]:
		_lay_run(t, c, sides[side], xs[side], sw, top + inset, bottom - inset)


## `ids` (indices into the tree's nodes) down from `y0` to `y1` at `x`, spread evenly.
func _lay_run(t: Dictionary, c: int, ids: Array, x: float, w: float, y0: float, y1: float) -> void:
	var total := 0.0
	for i in ids:
		total += FILLER_H if t["nodes"][i].get("filler", false) else NODE_H
	var gap: float = (y1 - y0 - total) / maxf(1.0, ids.size() - 1)
	var y: float = y0
	for i in ids:
		var nd: Dictionary = t["nodes"][i]
		var filler: bool = nd.get("filler", false)
		var h: float = FILLER_H if filler else NODE_H
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
	if filler:
		t["name"] = UI.label(b, Rect2(8, 0, rect.size.x - 16, rect.size.y), "", "Medium", Pal.CELL_TEXT - 4, Pal.TEXT_2, HORIZONTAL_ALIGNMENT_CENTER, false)
	else:
		t["name"] = UI.label(b, Rect2(10, 4, rect.size.x - 20, 22), "", "SemiBold", NAME_SIZES[0], Pal.TEXT, HORIZONTAL_ALIGNMENT_LEFT, false)
		t["line"] = UI.label(b, Rect2(10, 25, rect.size.x - 20, 18), "", "Regular", Pal.CELL_TEXT - 4, Pal.TEXT_3, HORIZONTAL_ALIGNMENT_LEFT, false)
	_tiles[id] = t
	layout[id] = Rect2(p.position + rect.position, rect.size)


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
	var big: bool = a.get("notable", false) or a.get("keystone", false)
	var edge: Color = Pal.TEXT if on else (Pal.ACCENT if taken else (Color(Pal.ACCENT, 0.55) if big else (Pal.TEXT_3 if reach else Pal.CARD_LINE)))
	var ground: Color = Pal.CARD.blend(Color(Pal.ACCENT, 0.12)) if taken else (Pal.CARD if reach else Pal.BG)
	var bw: int = 2 if (on or taken) else 1
	var b: Button = t["button"]
	b.add_theme_stylebox_override("normal", UI.box(ground, 6, bw, edge))
	b.add_theme_stylebox_override("hover", UI.box(Pal.BUTTON, 6, bw, edge))
	b.add_theme_stylebox_override("pressed", UI.box(Pal.BUTTON_PRESS, 6, bw, edge))
	b.add_theme_stylebox_override("focus", UI.box(Color.TRANSPARENT, 6, 2, Pal.TEXT))
	b.tooltip_text = str(a.get("words", ""))
	var nm: String = str(a.get("name", ""))
	var lit: Color = Pal.TEXT if (taken or reach) else Pal.TEXT_2
	if t["filler"]:
		_fit_name(t["name"], nm, [Pal.CELL_TEXT - 4, Pal.CELL_TEXT - 5])
		t["name"].add_theme_color_override("font_color", Pal.ACCENT if taken else lit)
		return
	_fit_name(t["name"], nm, NAME_SIZES)
	t["name"].add_theme_color_override("font_color", lit)
	var line: Array
	if taken:
		line = ["rank %d of %d" % [st["rank"], st["max"]], "%d of %d" % [st["rank"], st["max"]]] if int(st["max"]) > 1 else ["taken"]
	elif a.get("keystone", false):
		line = ["keystone · %d points in" % Data.MAP_KEYSTONE_POINTS, "keystone · %d in" % Data.MAP_KEYSTONE_POINTS, "keystone"]
	elif a.get("notable", false):
		line = ["notable" + (" · %d ranks" % int(st["max"]) if int(st["max"]) > 1 else ""), "notable"]
	else:
		line = ["a node · %d ranks" % int(st["max"]) if int(st["max"]) > 1 else "a node", "a node"]
	UI.fit(t["line"], line)
	t["line"].add_theme_color_override("font_color", Pal.ACCENT if (taken or big) else Pal.TEXT_3)


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
		if _tiles[id].has("line"):
			out.append(_tiles[id]["line"])
	return out
