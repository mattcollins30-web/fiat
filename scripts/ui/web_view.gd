extends Control
## The skill web (3 Nov, docs/design/skill_web.md; the target: the canvas's sw_final6): one web every runner lights its
## own path on - the centre, six element flowers round it, a class between each two, each class four small flowers -
## drawn in the Training room's body from the sim's layout (Data.web_ids / web_at / web_links), the paragon ring
## round the outside. Panned with the right button, zoomed with the wheel, a node picked with the left.
##
## A node's three states: owned (lit in its region's colour, a glow), can take (Sim.web_frontier: an amber ring), not
## yet (dark). The centre is amber, an element and its joins its colour, a class white. The twelve names sit in their
## regions, on no node.
##
## Signals: `picked(id)` when a node is clicked ("" for a click on nothing).
##
## The canvas is a base - the camera, the drawing, the input - with the web it draws behind hooks (node_of, links_all,
## lay_out, state_sig, state_for, region_words, stack_of, draw_between); Training's web is the default (yard_web.gd, the
## Pitch's old canvas, unused since 28 Oct, overrides them).

signal picked(id: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const Items := preload("res://scripts/sim/items.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")
const Layout := preload("res://scripts/sim/web_layout.gd")     # the layout (its class_name, WebLayout, preloaded)

const STEP := 80.0                 # a column along a lane (yard_web.gd lays out by it)
const ROW := 26.0
const ZOOM_MIN := 0.18
const ZOOM_MAX := 3.2
const ZOOM_STEP := 1.15
const LABEL_ZOOM := 2.0            # the nodes' names show from here; the hovered and the picked always
## The nodes' sizes in web units (the layout's 1000 box: a class flower's ring is 34 across its centre, its slots 26
## apart, a join's nodes 19, two notables on a run 22, a far flower's capstone 26 from its keystone): every pair clears by
## 4 (the smoke). A diamond's size is its half diagonal, so a keystone at 10 reads as big as a notable's disc and more.
const R_SMALL := 4.5
const R_NOTABLE := 8.5
const R_START := 10.0
const R_KEYSTONE := 10.0
const R_CAPSTONE := 11.5
const R_RING_NODE := 9.0
const R_PLAIN := R_SMALL           # (yard_web.gd's names for its own sizes)
const R_FILLER := R_SMALL
const LINK_W := 2.0
const LINK_DIM := Color("4a5059")       # a link to nothing reached yet
const LINK_CLASS_DIM := Color("5a616b")  # a class's: a shade lighter, the class's grey (its nodes are white when lit)
const ELEMENT_LINK_DIM := 0.45          # an element's (or the centre's) link not lit: its colour at this
const RING_DIM := 0.35                  # a dark node's ring: the card line with this of its region's colour
const GLOW := 0.2                       # an owned node's glow, its colour at this
const GLOW_R := 1.9                     # and its size against the node's
## The centre in amber (3 Nov, Matt's canvas): the camp's sand, apart from The cold's blue and the frontier's ring.
const PITCH_TONE := Color("d1a65f")
const FRONTIER := Pal.ACCENT
const PIC_ZOOM := 0.5              # a big node's picture from here; its glyph before
const R_RING := Data.RING_R        # the paragon ring, round the outside (the web's radius is 474 at the far tips)
const RING_DASH := 10.0
const RING_LABEL_DEG := -132.0     # the ring's name, outside it at the top left: the Recruit's corner, clear of the tabs
const NAME_SIZE := 14              # the twelve names on the web, at any zoom
const BOUNDS_PAD := 44.0           # past the ring: its nodes and its name
static var assume_pics := false   # the smoke: kept for the old checks (every node's size is its kind's now)

var sim
var selected := ""
var hover := ""
var cam := Vector2.ZERO            # the web point at the view's centre
var zoom := 1.0
var zoom_min := ZOOM_MIN           # Training's: the whole web, no further out (its names are placed for that zoom)
var layout := {}                   # id -> Vector2, web space
var _trees := {}                   # (yard_web.gd) tree name -> its dictionary
var _axis := {}                    # a region's name: key -> {"anchor", "label_at", "label_box", "words", "tone"}
var _region := {}                  # id -> "centre", "el:<tree>", "join", "class:<Class>" or "ring"
var _kind := {}                    # id -> small / notable / keystone / capstone / start / ring
var _tone := {}                    # id -> its region's colour
var _links := {}                   # id -> ids, both ways
var _nodes := {}                   # id -> the node's dictionary with its web kind, read once
var _drag := false
var _drag_from := Vector2.ZERO
var _cam_from := Vector2.ZERO
var _state := {}                   # id -> {"taken", "active", "reach", "theirs", "cost"} as last shown
var _state_sig := ""
var _font: Font
var _font_bold: Font
var _focused := false              # the first show frames the whole web
var _bounds := Rect2()
var slice_restate := false         # (BUILD45's slices: the web's 379 nodes restate whole now, in well under a millisecond)
var _stale := {}                   # (always empty: kept for the tests' reads)


func _init(sz: Vector2) -> void:
	size = sz
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	_font = UI.font("Regular", false)
	_font_bold = UI.font("SemiBold", false)
	lay_out()


# ------------------------------------------------------------------ the layout

static var _slot_of := {}          # the layout's slot name -> its dictionary (web_layout.gd), read once
static var _el_at := {}            # an element's index in the layout ("0".."5") -> its tree's name


static func _slots_index() -> void:
	if not _slot_of.is_empty():
		return
	for s in Layout.SLOTS:
		_slot_of[str(s["slot"])] = s
		var sn: String = str(s["slot"])
		if sn.ends_with("_n") and sn.begins_with("e"):
			_el_at[sn.substr(1, sn.length() - 3)] = str(s["tree"])


## The web's links of a node: the sim's (Data.web_links).
static func web_links_of(id: String) -> Array:
	return Data.web_links(id)


## Every node at the sim's place (web units, the centre at 0,0, 12 o'clock up), its region, kind and colour; the ring's
## thirty round the outside at their angles; the twelve names placed.
func lay_out() -> void:
	_slots_index()
	layout = {}
	_pick_cache = {}
	_trees = {}
	_axis = {}
	_region = {}
	_kind = {}
	_tone = {}
	_links = {}
	_nodes = {}
	for id in Data.web_ids():
		var sid := str(id)
		layout[sid] = Data.web_at(sid)
		_region[sid] = Data.web_region(sid)
		_kind[sid] = Data.web_kind(sid)
	for sid in layout:
		_tone[sid] = region_tone(sid)
		_links[sid] = web_links_of(str(sid)).duplicate()
	# the ring (slice 4): its nodes round the outside at their angles, joined round
	var ring: Dictionary = Data.RING
	for i in range(ring["nodes"].size()):
		var rid: String = "%s/%d" % [ring["name"], i]
		layout[rid] = Data.web_at(rid)              # on Data.RING_R, at its angle
		_region[rid] = "ring"
		_kind[rid] = "ring"
		_tone[rid] = Pal.ACCENT
		var out: Array = []
		for j in ring["nodes"][i].get("links", []):
			out.append("%s/%d" % [ring["name"], int(j)])
		_links[rid] = out
	# the names: a class's in the middle of its four flowers, an element's by its flower's centre, the ring's outside it
	for cd in Data.CLASSES:
		var key: String = "class:%s" % cd["name"]
		var mid := Vector2.ZERO
		var n := 0
		for id in layout:
			if _region[id] == key:
				mid += layout[id]
				n += 1
		if n > 0:
			_axis[key] = {"anchor": mid / n, "words": str(cd["name"]), "tone": Pal.TEXT}
			_trees[key] = {"name": key, "class": str(cd["name"])}     # what each name is (the tests' reads, as the trees were)
	for i in range(6):
		var tn: String = str(_el_at.get(str(i), ""))
		if tn == "":
			continue
		var key: String = "el:" + tn
		var at := Vector2.ZERO
		var n := 0
		for id in layout:
			if _region[id] == key:
				at += layout[id]
				n += 1
		var flower: Dictionary = _slot_of.get("e%d_n" % i, {})
		if not flower.is_empty():
			at = Vector2(float(flower["at"][0]), float(flower["at"][1]))     # by the flower, not out along its run
		elif n > 0:
			at /= n
		_axis[key] = {"anchor": at, "words": plain_name(tn), "tone": element_tone(tn)}
		_trees[key] = {"name": key, "element": Data.tree_named(tn).get("element", "")}
	_trees["ring"] = {"name": "ring", "ring": true}
	_axis["ring"] = {"anchor": Vector2.from_angle(deg_to_rad(RING_LABEL_DEG)) * (R_RING + 24.0), "words": plain_name(Data.RING_TREE), "tone": Pal.ACCENT}
	_find_bounds()
	_labels_by_entry()


## A region's colour: the centre amber, an element (and its joins) its own, a class white, the ring the accent.
func region_tone(id: String) -> Color:
	var rg: String = str(_region.get(id, ""))
	if rg == "centre":
		return PITCH_TONE
	if rg.begins_with("el:"):
		return element_tone(rg.substr(3))
	if rg == "join":
		return element_tone(join_element(id))
	if rg == "ring":
		return Pal.ACCENT
	return Pal.TEXT


## An element tree's colour (its damage type's, as the stats and the items carry it).
static func element_tone(tn: String) -> Color:
	for t in Data.ELEMENT_TREES:
		if str(t["name"]) == tn:
			return Pal.ELEMENT_COLOURS.get(str(t.get("element", "")), Pal.TEXT)
	return Pal.TEXT


## A join's element: the layout's slot "x<element>L/R<n>" (a join is its element's colour, the spec).
func join_element(id: String) -> String:
	_slots_index()
	var sn: String = Data.web_slot(id)
	if sn.begins_with("x") and sn.length() > 1:
		return str(_el_at.get(sn.substr(1, 1), ""))
	for o in _links.get(id, []):
		if str(_region.get(o, "")).begins_with("el:"):
			return str(_region[o]).substr(3)
	return ""


## A centre small's stat (the layout's pool: stat:hp, stat:guard, stat:pace) as its letter, L, G or P; else "".
func stat_letter(id: String) -> String:
	_slots_index()
	var pool: String = str(_slot_of.get(Data.web_slot(id), {}).get("pool", ""))
	return {"stat:hp": "L", "stat:guard": "G", "stat:pace": "P"}.get(pool, "")


## A region's name over it: the name alone (28 Oct, Matt: "it should just say 'Rat Man' ... same for the classes, just
## the class names") - no "The".
static func plain_name(tn: String) -> String:
	var n: String = tn.trim_prefix("The ").trim_prefix("the ")
	return n.left(1).to_upper() + n.substr(1) if n != "" else tn


## The twelve names (and the ring's) placed for the whole web's zoom - the furthest out the canvas goes - so closer in
## each only shrinks about its point: centred on the first place by its region's point, then out a step at a time, whose
## words cover no node and no name already placed. A name that lands far goes first and the lot again (LABEL_TRIES).
const LABEL_TRIES := 6
const LABEL_NEAR := 120.0           # a name within this of its region's point is by it (the smoke's reach)
const LABEL_STEP := 6.0             # the places tried, a grid this fine out to LABEL_NEAR, nearest first
static var _label_grid: Array = []


## The offsets a name tries, nearest first.
static func label_grid() -> Array:
	if _label_grid.is_empty():
		var n: int = int(LABEL_NEAR / LABEL_STEP)
		for gx in range(-n, n + 1):
			for gy in range(-n, n + 1):
				var d := Vector2(gx, gy) * LABEL_STEP
				if d.length() <= LABEL_NEAR:
					_label_grid.append(d)
		_label_grid.sort_custom(func(a, b): return a.length() < b.length() or (a.length() == b.length() and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	return _label_grid


func _labels_by_entry() -> void:
	var order: Array = _axis.keys()
	_index_nodes(func(id): return radius_by_kind(str(_kind.get(id, "small"))))
	for attempt in range(LABEL_TRIES):
		var far_one: String = _labels_in(order)
		if far_one == "":
			break
		order.erase(far_one)
		order.push_front(far_one)
	_near = {}


## The zoom the names are placed for: the whole web's.
func fit_zoom() -> float:
	return clampf(minf(size.x / _bounds.size.x, size.y / _bounds.size.y), ZOOM_MIN, ZOOM_MAX)


## A name's box in web units at zoom `z`, centred on `at`.
func label_box_at(key: String, at: Vector2, z: float) -> Rect2:
	var w: float = _font_bold.get_string_size(str(_axis[key]["words"]), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x * LABEL_SLACK / z
	var h: float = NAME_SIZE * 1.15 / z
	return Rect2(at.x - w / 2.0, at.y - h / 2.0, w, h)


const LABEL_SLACK := 1.06          # the words measured a little wide: Windows' shaping runs a few px wider than the cloud's (25 Oct)


## One placement in `order`; the first name that landed further than LABEL_NEAR from its point, or none.
func _labels_in(order: Array) -> String:
	var far_one := ""
	var placed: Array = []
	var z: float = fit_zoom()
	for key in order:
		var ax: Dictionary = _axis[key]
		var p: Vector2 = ax["anchor"]
		var best: Array = []
		for d in label_grid():
			var at: Vector2 = p + d
			var box: Rect2 = label_box_at(key, at, z)
			if _bounds.encloses(box) and _label_clear(box, placed):
				best = [at, box]
				break
		if best.is_empty():
			best = [p, label_box_at(key, p, z)]       # nowhere clear: the retry puts it first
			if far_one == "":
				far_one = key
		ax["label_at"] = best[0]
		ax["label_box"] = best[1]
		placed.append(best[1])
		if far_one == "" and p.distance_to(best[0]) > LABEL_NEAR - LABEL_STEP:
			far_one = key
	return far_one


## A region's name on screen as drawn at this zoom (for the smoke and the hover).
func label_rect(key: String) -> Rect2:
	var ax: Dictionary = _axis.get(key, {})
	if not ax.has("label_at"):
		return Rect2()
	var p: Vector2 = to_screen(ax["label_at"])
	var w: float = _font_bold.get_string_size(str(ax["words"]), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
	return Rect2(p.x - w / 2.0, p.y - NAME_SIZE * 0.55, w, NAME_SIZE * 1.1)


## BUILD45 (2 Nov, perf44 3): the nodes bucketed by place for one pass, each one's radius read once. A pass only.
const NEAR_CELL := 128.0
var _near := {}                        # Vector2i bucket -> ids
var _rad := {}                         # id -> radius, for the pass
var _rad_max := 0.0


func _index_nodes(radius: Callable) -> void:
	_near = {}
	_rad = {}
	_rad_max = 0.0
	for id in layout:
		var p: Vector2 = layout[id]
		var c := Vector2i(floori(p.x / NEAR_CELL), floori(p.y / NEAR_CELL))
		if not _near.has(c):
			_near[c] = []
		_near[c].append(id)
		var r: float = float(radius.call(id))
		_rad[id] = r
		_rad_max = maxf(_rad_max, r)


## The ids bucketed under a box (every node inside it among them).
func _ids_in(box: Rect2) -> Array:
	var out: Array = []
	for cx in range(floori(box.position.x / NEAR_CELL), floori(box.end.x / NEAR_CELL) + 1):
		for cy in range(floori(box.position.y / NEAR_CELL), floori(box.end.y / NEAR_CELL) + 1):
			var b = _near.get(Vector2i(cx, cy))
			if b != null:
				out.append_array(b)
	return out


func _label_clear(box: Rect2, placed: Array) -> bool:
	for b in placed:
		if box.intersects(b):
			return false
	if not _near.is_empty():
		for id in _ids_in(box.grow(_rad_max + 2.0)):
			if box.grow(float(_rad[id]) + 2.0).has_point(layout[id]):
				return false
		return true
	for id in layout:
		if box.grow(radius_by_kind(str(_kind.get(id, "small"))) + 2.0).has_point(layout[id]):
			return false
	return true


func _find_bounds() -> void:
	var r: float = R_RING + BOUNDS_PAD
	_bounds = Rect2(-r, -r, 2.0 * r, 2.0 * r)
	zoom_min = fit_zoom()


# ------------------------------------------------------------------ the hooks (Training's web by default)

## A node: the sim's (sim.node), its web kind beside it, read once.
func node_of(id: String) -> Dictionary:
	if _nodes.has(id):
		return _nodes[id]
	var nd: Dictionary = {}
	if sim != null:
		nd = sim.node(id).duplicate()
	nd["web_kind"] = str(_kind.get(id, "small"))
	if sim != null:
		_nodes[id] = nd
	return nd


func links_all() -> Dictionary:
	return _links


## The signature of what the state reads: a change restates the web.
func state_sig() -> String:
	return "%s|%s|%d|%d|%d|%s|%s|%d" % [str(sim.tree), sim.cls, sim.web_points(), sim.web_spent(), sim.web_free(), selected, str(sim.ring), sim.paragon_free()]


## A node's state as drawn: taken (owned), active, reach (Sim.web_frontier: takeable now), theirs (unused now), cost.
func state_for(id: String) -> Dictionary:
	if _region.get(id, "") == "ring":
		var on: int = int(sim.ring.get(id, 0))
		var top: int = int(node_of(id).get("stack", 1))
		var ring_reach: bool = on < top and sim.paragon_free() > 0 and (node_of(id).get("entry", false) or on > 0 or _links.get(id, []).any(func(o): return int(sim.ring.get(o, 0)) > 0))
		return {"taken": on > 0, "active": on > 0, "reach": ring_reach, "theirs": false, "cost": 1, "block": ""}
	var owned: bool = sim.web_owned(id)
	var reach: bool = (_frontier.has(id) if _frontier_read else sim.web_frontier(true).has(id)) and not owned
	return {"taken": owned, "active": owned, "reach": reach, "theirs": false, "cost": 1, "block": ""}


var _frontier := {}
var _frontier_read := false


## A node's points on it of its stack, [n, top], or [] for a plain node.
func stack_of(id: String, nd: Dictionary) -> Array:
	if nd.has("ring"):
		return [int(sim.ring.get(id, 0)), int(nd["stack"])]
	return []


func region_words(tn: String) -> String:
	return str(_axis.get(tn, {}).get("words", plain_name(tn)))


## A node's glyph key (node_glyphs.gd), or "" for none.
func glyph_of(nd: Dictionary) -> String:
	return NodeGlyphs.of(nd)


## A node's level tag as [words, met], or [] (the web's big nodes open on points spent: the card and the key say it).
func level_tag(_nd: Dictionary) -> Array:
	return []


## What's drawn between the links and the nodes: nothing on Training's (a pair's halves face each other across a join).
func draw_between(_view: Rect2) -> void:
	pass


## A tree's tone: an element's colour, the centre's amber, a class's white.
func tone_of(key: String) -> Color:
	if _tone.has(key):
		return _tone[key]
	if key == "centre":
		return PITCH_TONE
	if key.begins_with("el:"):
		return element_tone(key.substr(3))
	return Pal.TEXT


## A region drawn in its own colour (its links and dark rings): the centre's, an element's, a join's.
func tinted(id: String) -> bool:
	var rg: String = str(_region.get(id, id))
	return rg == "centre" or rg.begins_with("el:") or rg == "join"


# ------------------------------------------------------------------ the camera

func to_screen(p: Vector2) -> Vector2:
	return (p - cam) * zoom + size / 2.0


func to_web(p: Vector2) -> Vector2:
	return (p - size / 2.0) / zoom + cam


## The whole web in the view.
func focus_all() -> void:
	cam = _bounds.get_center()
	zoom = clampf(minf(size.x / _bounds.size.x, size.y / _bounds.size.y), zoom_min, ZOOM_MAX)
	queue_redraw()


## The nodes of these regions filling the view.
func focus_regions(regions: Array) -> void:
	var box := Rect2()
	var first := true
	for id in layout:
		if str(_region.get(id, "")) in regions:
			if first:
				box = Rect2(layout[id], Vector2.ZERO)
				first = false
			else:
				box = box.expand(layout[id])
	if first:
		focus_all()
		return
	box = box.grow(R_CAPSTONE + 6.0)
	var avail := Vector2(size.x - 2.0 * FRAME_PAD, size.y - FRAME_TOP - FRAME_PAD)     # under the tabs (the review of the corner's first render)
	zoom = clampf(minf(avail.x / box.size.x, avail.y / box.size.y), zoom_min, ZOOM_MAX)
	cam = box.get_center() - Vector2(0.0, (FRAME_TOP - FRAME_PAD) / 2.0) / zoom
	queue_redraw()


const FRAME_TOP := 52.0            # a region framed: clear of the tabs over the canvas's top
const FRAME_PAD := 12.0
## The canvas under the tabs: where a framed region's nodes all fall (the smoke).
func framed_rect() -> Rect2:
	return Rect2(FRAME_PAD, FRAME_TOP, size.x - 2.0 * FRAME_PAD, size.y - FRAME_TOP - FRAME_PAD)


## One region filling the view ("centre", "el:<tree>", "class:<Class>"; a tree's name for the old canvases).
func focus_tree(tree_name: String) -> void:
	focus_regions([tree_name])


## A class's corner (3 Nov): its four flowers and its two elements, the joins between them.
func focus_class(cls: String) -> void:
	focus_regions(corner_regions(cls))


## The class's region and the two elements its start's joins run to.
func corner_regions(cls: String) -> Array:
	var key: String = "class:" + cls
	var out: Array = [key]
	for id in layout:
		if _region[id] != key:
			continue
		for o in _links.get(id, []):
			if _region.get(o, "") == "join":
				var el: String = "el:" + join_element(str(o))
				if not (el in out):
					out.append(el)
	return out


# ------------------------------------------------------------------ the state

var _labels_sim := false
func show_state(s) -> void:
	sim = s
	if not _labels_sim:
		_labels_sim = true
		_pack_all()
	if not _focused:
		_focused = true
		focus_all()
	var sig := state_sig()
	if sig != _state_sig:
		_state_sig = sig
		_state = {}
		_restate()
	queue_redraw()


## Every node restated: the frontier read once for the lot.
func _restate() -> void:
	_frontier = {}
	if sim != null and sim.has_method("web_frontier"):
		for id in sim.web_frontier(true):          # joined and gated, points or not: the amber ring says where the next point goes
			_frontier[str(id)] = true
	_frontier_read = true
	for id in layout:
		_state[id] = state_for(id)
	_frontier_read = false


## The nodes still to restate after a change (the tests): none - the web restates whole.
func restates_waiting() -> int:
	return _stale.size()


## BUILD45 (2 Nov, perf44 3): Training's first open packed every picture; the same work ahead of it, a step a frame
## while the game runs (main._warm_rooms). True once done (or the canvas has been shown).
var _warm_ids: Array = []
var _warm_at := 0
var _warm_phase := 0
func warm_step(s, budget_us := 4000) -> bool:
	if _labels_sim:
		return true
	sim = s
	if _warm_phase == 0:
		for kind in ["disc", "diamond", "square"]:         # _pack_all's order, so the atlas packs as it did
			for n in DISC_SIZES:
				shape(kind, n / 2.0)
		_warm_ids = layout.keys()
		_warm_at = 0
		_warm_phase = 1
		return false
	if _warm_phase == 1:
		var t0 := Time.get_ticks_usec()
		while _warm_at < _warm_ids.size() and Time.get_ticks_usec() - t0 < budget_us:
			var nd: Dictionary = node_of(str(_warm_ids[_warm_at]))
			_warm_at += 1
			atlased(picture(picture_slug(nd)))
			if glyph_of(nd) != "":
				atlased(NodeGlyphs.texture(glyph_of(nd)))
		if _warm_at >= _warm_ids.size():
			_atlas_flush()                       # the pictures sent up, a step of its own
			_warm_phase = 2
		return false
	if _warm_phase == 2:
		_ensure_bends()                          # the curved links, a step of their own
		_warm_phase = 3
		return false
	_labels_sim = true
	_pack_all()                              # what's left of it (the atlas and the bends are in)
	return true


func state_of(id: String) -> Dictionary:
	return _state.get(id, {})


# ------------------------------------------------------------------ drawing

## A node's picture (23 Oct, the art): art/nodes/<slug>.png when the file exists, else "" and the glyph draws. The
## hooks name the slug (Training's: the node's name; the Map's, the Pitch's and the ring's their own).
static var _pics := {}
func picture_slug(nd: Dictionary) -> String:
	if nd.has("ring"):
		return "ring_" + str(nd.get("key", ""))
	if nd.has("skill"):
		return "skill/" + str(nd["skill"])         # a skill node draws the skill's own picture (art/skills/<id>.png, 24 Oct)
	return Items.slug(str(nd.get("name", "")))


static func picture(slug: String) -> Texture2D:
	if slug == "":
		return null
	if slug.begins_with("skill/"):
		return art_at("res://art/skills/%s.png" % slug.substr(6))
	return art_at("res://art/nodes/%s.png" % slug)


## A picture by path, looked for once (23 Oct): the nodes', the regions' emblems, the canvases' backdrops.
static func art_at(path: String) -> Texture2D:
	if _pics.has(path):
		return _pics[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)     # null, quietly, where a clone's import cache isn't built yet (the review)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))     # a clone without the import cache (the cloud's renders): the file itself
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_pics[path] = tex
	return tex


## The atlas (23 Oct, Matt: the fans spun on the skill tree). The web drew ~2,500 draw calls a frame at the whole
## web: every disc, ring and polygon is a call of its own, and a node's picture between them broke the batch again.
## Every node is drawn from one texture now - its disc, its ring (a disc of the line's colour under the fill's), its
## picture, its glyph, the regions' emblems - packed here on first use, so the nodes batch into one call; the links
## and the words follow in passes of their own. Shared by the three canvases. Linear-filtered as the textures were,
## each cell's edge pixels copied into its padding so a picture's edge samples as it did standalone.
const ATLAS := 2048
const ATLAS_PAD := 2
const DISC_SIZES := [16, 32, 64, 128]   # the disc and the diamond in four sizes, each drawn at most halved
static var _atlas_img: Image
static var _atlas_tex: ImageTexture
static var _atlas_of := {}               # a texture's instance id (or a shape's key) -> its AtlasTexture, or the texture where it didn't pack
static var _atlas_dirty := false
static var _shelf := Vector3i(0, 0, 0)   # the packing's x, y and the shelf's height
static var atlas_misses := 0             # textures that didn't pack (the smoke: none)


## A texture's region of the atlas, packed the first time it's asked for; the texture itself where it can't be.
static func atlased(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key: int = tex.get_instance_id()
	if _atlas_of.has(key):
		return _atlas_of[key]
	var img: Image = tex.get_image()
	if (img == null or img.is_empty()) and tex.resource_path != "" and FileAccess.file_exists(tex.resource_path):
		img = Image.load_from_file(ProjectSettings.globalize_path(tex.resource_path))
	var out: Texture2D = _pack(img)
	if out == null:
		atlas_misses += 1
		out = tex
	_atlas_of[key] = out
	return out


## A disc or a diamond ("disc" / "diamond"), white, anti-aliased, for a radius on screen: the smallest of
## DISC_SIZES that holds it, so it's never shrunk past half.
static func shape(kind: String, radius: float) -> Texture2D:
	var n: int = DISC_SIZES[-1]
	for s in DISC_SIZES:
		if s >= radius * 2.0:
			n = s
			break
	var key := "%s:%d" % [kind, n]
	if _atlas_of.has(key):
		return _atlas_of[key]
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var h: float = n / 2.0
	for y in range(n):
		for x in range(n):
			var d := Vector2(x + 0.5 - h, y + 0.5 - h)
			var cover: float = h - d.length() if kind == "disc" else (h - absf(d.x) - absf(d.y)) / sqrt(2.0)
			if kind == "square":                 # a rounded square, its corners a third of the half
				var rc: float = h * 0.33
				var q := Vector2(absf(d.x), absf(d.y)) - Vector2(h - rc, h - rc)
				cover = -(Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - rc)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(cover + 0.5, 0.0, 1.0)))
	var out: Texture2D = _pack(img)
	if out == null:
		atlas_misses += 1
		out = ImageTexture.create_from_image(img)
	_atlas_of[key] = out
	return out


static func _pack(src: Image) -> AtlasTexture:
	if src == null or src.is_empty():
		return null
	var img: Image = src.duplicate()
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var w: int = img.get_width()
	var h: int = img.get_height()
	if _atlas_img == null:
		_atlas_img = Image.create(ATLAS, ATLAS, false, Image.FORMAT_RGBA8)
		_atlas_tex = ImageTexture.create_from_image(_atlas_img)
	if _shelf.x + w + 2 * ATLAS_PAD > ATLAS:
		_shelf = Vector3i(0, _shelf.y + _shelf.z, 0)     # the next shelf
	if _shelf.y + h + 2 * ATLAS_PAD > ATLAS or w + 2 * ATLAS_PAD > ATLAS:
		return null
	var at := Vector2i(_shelf.x + ATLAS_PAD, _shelf.y + ATLAS_PAD)
	var whole := Rect2i(0, 0, w, h)
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			_atlas_img.blit_rect(img, whole, at + Vector2i(dx, dy) * (ATLAS_PAD - 1))     # the edge into the padding, then the picture over it
	_atlas_img.blit_rect(img, whole, at)
	_shelf = Vector3i(_shelf.x + w + 2 * ATLAS_PAD, _shelf.y, maxi(_shelf.z, h + 2 * ATLAS_PAD))
	_atlas_dirty = true
	var a := AtlasTexture.new()
	a.atlas = _atlas_tex
	a.region = Rect2(at, Vector2(w, h))
	return a


## The atlas's new cells sent up, once a frame at most (the pictures land on the first draws, then never again).
static func _atlas_flush() -> void:
	if _atlas_dirty and _atlas_tex != null:
		_atlas_tex.update(_atlas_img)
		_atlas_dirty = false


## Everything this canvas can draw packed at once, on its first show (the review): packed lazily, a pan across the
## web packed a few pictures a frame and sent the whole atlas up on each of them.
func _pack_all() -> void:
	for kind in ["disc", "diamond", "square"]:
		for n in DISC_SIZES:
			shape(kind, n / 2.0)
	for id in layout:
		var nd: Dictionary = node_of(id)
		atlased(picture(picture_slug(nd)))
		if glyph_of(nd) != "":
			atlased(NodeGlyphs.texture(glyph_of(nd)))
	_atlas_flush()
	_ensure_bends()                        # the curved links worked here too, not on a pan's first frame


## The canvas's backdrop (23 Oct, the manifest): art/web/backdrop_<slug>.png under everything, covering the view.
func backdrop_slug() -> String:
	return "training"


## A region's emblem (23 Oct, the manifest): art/web/region_<slug>.png.
const EMBLEM := 26.0
func emblem_of(tn: String) -> Texture2D:
	return art_at("res://art/web/region_%s.png" % Items.slug(tn))


## A node's radius in web units, by its web kind (or, on the old canvases, its flags).
func radius_of(nd: Dictionary) -> float:
	if nd.has("web_kind"):
		return radius_by_kind(str(nd["web_kind"]))
	if nd.get("capstone", false):
		return R_CAPSTONE
	if nd.get("keystone", false):
		return R_KEYSTONE
	if nd.get("notable", false):
		return R_NOTABLE
	return R_SMALL


static func radius_by_kind(k: String) -> float:
	match k:
		"capstone":
			return R_CAPSTONE
		"keystone":
			return R_KEYSTONE
		"notable":
			return R_NOTABLE
		"start":
			return R_START
		"ring":
			return R_RING_NODE
	return R_SMALL


## Whether a node carries its picture (a notable, keystone, capstone, the start, a ring node); the smalls are dots.
static func big_kind(k: String) -> bool:
	return k in ["notable", "keystone", "capstone", "start", "ring"]


## The frame in passes (23 Oct, the fans): the backdrop and the hulls; the links, one call a colour; the joins; every
## node's disc, ring and picture from the atlas, one call; the regions' emblems from it too; then the words, grouped by
## font and size. `batches` counts the calls as the canvas issues them (the smoke holds it under BATCH_MAX).
const BATCH_MAX := 60
var batches := 0
var dry := false                       # the smoke: the frame's passes run and count, nothing drawn (it never draws headless)
var nodes_drawn := 0                   # the nodes the last frame drew (the smoke: every web node at the whole web)
var _batch_key := ""
var _texts := {}                       # "font:size" -> [[font, at, words, size, colour]], the words' pass


## The calls a frame takes here, the passes run dry (the smoke can't draw).
func count_batches() -> int:
	dry = true
	_draw()
	dry = false
	return batches


func _tally(key: String) -> void:
	if key == "" or key != _batch_key:
		batches += 1                       # a polygon is a call of its own (""); a run of the same texture is one
	_batch_key = key


func _sprite(tex: Texture2D, rect: Rect2, col: Color = Color.WHITE) -> void:
	if tex == null:
		return
	_tally("atlas" if tex is AtlasTexture and (tex as AtlasTexture).atlas == _atlas_tex else "tex:%d" % tex.get_instance_id())
	if not dry:
		draw_texture_rect(tex, rect, false, col)


func _shape(kind: String, p: Vector2, radius: float, col: Color) -> void:
	if radius > 0.0:
		_sprite(shape(kind, radius), Rect2(p - Vector2(radius, radius), Vector2(radius, radius) * 2.0), col)


func _text(font: Font, at: Vector2, words: String, fs: int, col: Color) -> void:
	var key := "%d:%d" % [font.get_instance_id(), fs]
	if not _texts.has(key):
		_texts[key] = []
	_texts[key].append([font, at, words, fs, col])


## The picked and hovered node's name under the label zoom (3 Nov, merge 47: drawn under its node it ran across the
## nodes beside it): below, above, right, left or a diagonal of it, a step further out each round - the first place
## whose plate covers no other node and no region's name and stays on the canvas (else the one covering fewest) - on a
## plate of the canvas's colour, with a lead when it sits further out. Only the nodes within the plate's reach are
## tried, and the place is kept per node and zoom (a pan or a hover's redraw reads it back; re-placed when it would
## leave the canvas). pick_label_rects / pick_label_hits: where each went and what it covers (the smoke's).
var _pick_labels: Array = []
var pick_label_rects := {}
var pick_label_hits := {}
var _pick_cache := {}                  # "id|zoom|size" -> [offset from the node, hits]
const PICK_PAD := 3.0
const PICK_OUTS := [4.0, 16.0, 28.0, 40.0, 52.0, 64.0, 76.0, 90.0]
func _draw_pick_labels() -> void:
	pick_label_rects = {}
	pick_label_hits = {}
	var canvas := Rect2(Vector2.ZERO, size)
	for pl in _pick_labels:
		var id: String = pl[0]
		var p: Vector2 = pl[1]
		var r: float = pl[2]
		var words: String = str(node_of(id).get("name", ""))
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		var th: float = _font.get_height(12)
		var sz := Vector2(tw + PICK_PAD * 2.0, th + PICK_PAD * 2.0)
		var ck := "%s|%.4f|%s" % [id, zoom, str(size)]
		var best := Rect2()
		var best_n := -1
		if _pick_cache.has(ck):
			var rc0 := Rect2(p + Vector2(_pick_cache[ck][0]), sz)
			if canvas.encloses(rc0):
				best = rc0
				best_n = int(_pick_cache[ck][1])
		if best_n < 0:
			var near: Array = _pick_near(id, p, r + float(PICK_OUTS.back()) + sz.length() + 8.0)
			best_n = 1 << 30
			for out in PICK_OUTS:
				for at in [p + Vector2(-sz.x / 2.0, r + out), p + Vector2(-sz.x / 2.0, -r - out - sz.y), p + Vector2(r + out + 2.0, -sz.y / 2.0),
						p + Vector2(-r - out - 2.0 - sz.x, -sz.y / 2.0), p + Vector2(r * 0.7 + out, r * 0.7 + out * 0.5), p + Vector2(-r * 0.7 - out - sz.x, r * 0.7 + out * 0.5),
						p + Vector2(r * 0.7 + out, -r * 0.7 - out * 0.5 - sz.y), p + Vector2(-r * 0.7 - out - sz.x, -r * 0.7 - out * 0.5 - sz.y)]:     # below, above, right, left, the four diagonals
					var rc := Rect2(at, sz)
					var n: int = _pick_covers(rc, near) + (0 if canvas.encloses(rc) else 1000)
					if n < best_n:
						best_n = n
						best = rc
					if best_n == 0:
						break
				if best_n == 0:
					break
			_pick_cache[ck] = [best.position - p, best_n]
		pick_label_rects[id] = best
		pick_label_hits[id] = best_n
		if not dry:
			var lead := Vector2(clampf(p.x, best.position.x, best.end.x), clampf(p.y, best.position.y, best.end.y))
			if lead.distance_to(p) > r + 10.0:
				draw_line(p + (lead - p).normalized() * (r + 2.0), lead, Color(pl[3], 0.7), 1.0, true)     # a lead from a plate set further out
			draw_rect(best, Color(Pal.BG, 0.88))
		_text(_font, best.position + Vector2(PICK_PAD, PICK_PAD + _font.get_ascent(12)), words, 12, pl[3])
	_pick_labels = []


## What a picked label could run into from `p` within `reach`: [[centre, radius]] for the nodes but `own`, and the
## regions' names as [rect].
func _pick_near(own: String, p: Vector2, reach: float) -> Array:
	var out: Array = []
	for oid in layout:
		if oid == own:
			continue
		var q: Vector2 = to_screen(layout[oid])
		if absf(q.x - p.x) <= reach and absf(q.y - p.y) <= reach:
			out.append([q, maxf(3.0, radius_of(node_of(oid)) * zoom) + 1.0])
	for key in _axis:
		var lr: Rect2 = label_rect(str(key))
		if lr.size.x > 0.0:
			out.append([lr])
	return out


func _pick_covers(rc: Rect2, near: Array) -> int:
	var n := 0
	for e in near:
		if e.size() == 1:
			if Rect2(e[0]).intersects(rc):
				n += 1
		else:
			var q: Vector2 = e[0]
			if Vector2(clampf(q.x, rc.position.x, rc.end.x), clampf(q.y, rc.position.y, rc.end.y)).distance_to(q) < float(e[1]):
				n += 1
	return n


## How many nodes other than `own` a rect on the canvas covers, and the regions' names it runs into (every node read).
func label_covers(rc: Rect2, own: String) -> int:
	return _pick_covers(rc, _pick_near(own, rc.get_center(), INF))


func _draw() -> void:
	batches = 0
	nodes_drawn = 0
	_batch_key = ""
	_texts = {}
	_tally("")
	if not dry:
		draw_rect(Rect2(Vector2.ZERO, size), Pal.BG)
	var bd: Texture2D = art_at("res://art/web/backdrop_%s.png" % backdrop_slug())
	if bd != null:
		# the backdrop covers the canvas whole, its proportions kept
		var k: float = maxf(size.x / bd.get_width(), size.y / bd.get_height())
		var bs: Vector2 = bd.get_size() * k
		_tally("backdrop")
		if not dry:
			draw_texture_rect(bd, Rect2((size - bs) / 2.0, bs), false, Color(1, 1, 1, 0.9))
	if sim == null:
		return
	var view := Rect2(Vector2.ZERO, size).grow(60.0)
	draw_under(view)
	_draw_links(view)
	draw_between(view)
	# the nodes
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		if not view.has_point(p):
			continue
		_draw_node(id, p)
	_draw_pick_labels()
	_draw_region_names(view)
	# the words last, a font and size at a time
	for key in _texts:
		_tally("text:" + key)
		for t in _texts[key]:
			if not dry:
				draw_string(t[0], t[1], t[2], HORIZONTAL_ALIGNMENT_LEFT, -1, t[3], t[4])
	_texts = {}
	_atlas_flush()


## The links, under the nodes: lit in the region's colour between two owned, amber to one that can be taken, dim
## otherwise (an element's and the centre's in their colour, faint); gathered by colour and width, one call each.
func _draw_links(view: Rect2) -> void:
	var runs := {}                         # [colour, width] -> PackedVector2Array of pairs
	_ensure_bends()
	var links: Dictionary = links_all()
	for a in links:
		for b in links[a]:
			if str(a) > str(b) or not layout.has(a) or not layout.has(b):
				continue              # each pair once (the links run both ways)
			var pa: Vector2 = to_screen(layout[a])
			var pb: Vector2 = to_screen(layout[b])
			if not view.has_point(pa) and not view.has_point(pb):
				continue
			var lit: bool = _state.get(a, {}).get("taken", false) and _state.get(b, {}).get("taken", false)
			var run := [link_colour(str(a), str(b)), LINK_W * (1.6 if lit else 1.0) * maxf(0.6, zoom)]
			if not runs.has(run):
				runs[run] = PackedVector2Array()
			var bent: PackedVector2Array = bend_of(str(a), str(b))
			if bent.is_empty():
				runs[run].append(pa)
				runs[run].append(pb)
			else:
				for k in range(bent.size() - 1):
					runs[run].append(to_screen(bent[k]))
					runs[run].append(to_screen(bent[k + 1]))
	for run in runs:
		_tally("lines")
		if not dry:
			draw_multiline(runs[run], run[0], run[1], true)


## A reachable link's colour, lighter than the region's (or darker where the colour's near white already).
static func reach_tone(tone: Color) -> Color:
	return tone.lerp(Color.WHITE, 0.4) if tone.get_luminance() < 0.7 else tone.darkened(0.35)


## A link's colour: the region's where both ends are owned (a link between two regions takes the coloured one's: an
## element's, a join's, the centre's), amber from an owned node to one that can be taken, dim otherwise - in its
## region's colour, faint, inside the centre, an element or a join.
func link_colour(a: String, b: String) -> Color:
	var sa: Dictionary = _state.get(a, {})
	var sb: Dictionary = _state.get(b, {})
	var key: String = a if tinted(a) else (b if tinted(b) else a)
	var tone: Color = tone_of(key)
	if sa.get("taken", false) and sb.get("taken", false):
		return tone
	if (sa.get("taken", false) and sb.get("reach", false)) or (sb.get("taken", false) and sa.get("reach", false)):
		return Color(FRONTIER, 0.85)
	if tinted(a) or tinted(b):
		return Color(tone, ELEMENT_LINK_DIM)
	return LINK_CLASS_DIM if str(_region.get(a, "")).begins_with("class:") else LINK_DIM


## A link's path in web space (23 Oct, Matt: Tough's line to Lucky ran straight through Keen, so it read as Tough to
## Keen - the wheel puts a node on the middle track at the same angle as two it lies between): straight, or where it
## would pass through a node that isn't one of its ends, a gentle curve bowed round it, the side that clears it first.
## Worked once a layout (_bends), drawn as short segments in the links' one call.
const BEND_CLEAR := 8.0                # the room a bent link leaves its node, past the node's own radius
const BEND_STEPS := 12
var _bends := {}                       # "a|b" -> the curve's points, web space, worked once
var _bends_for := Vector3.ZERO         # the layout they were worked for: its size and its points' sum (a moved layout re-works them, the review)


func _layout_sig() -> Vector3:
	var sum := Vector2.ZERO
	for id in layout:
		sum += layout[id]
	return Vector3(layout.size(), sum.x, sum.y)


## The bends worked for the layout as it stands: once a frame at most (the sum walks every node).
func _ensure_bends() -> void:
	if _bends_for != _layout_sig():
		_find_bends()


## A bent link's points, web space; empty for a straight one. _ensure_bends first.
func bend_of(a: String, b: String) -> PackedVector2Array:
	return _bends.get(a + "|" + b if a < b else b + "|" + a, PackedVector2Array())


func link_path(a: String, b: String) -> PackedVector2Array:
	_ensure_bends()
	var bent: PackedVector2Array = bend_of(a, b)
	return bent if not bent.is_empty() else PackedVector2Array([layout[a], layout[b]])


func _curve(pa: Vector2, c: Vector2, pb: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in range(BEND_STEPS + 1):
		var t: float = float(k) / BEND_STEPS
		out.append(pa.lerp(c, t).lerp(c.lerp(pb, t), t))     # the quadratic through the control point
	return out


## How far a path comes short of clearing the nodes it passes, its ends aside (0: clear).
func _blockers(path: PackedVector2Array, a: String, b: String) -> float:
	var worst := 0.0
	var box := Rect2(path[0], Vector2.ZERO)
	for q in path:
		box = box.expand(q)
	box = box.grow(R_CAPSTONE + BEND_CLEAR + 4.0)
	for id in (_ids_in(box) if not _near.is_empty() else layout.keys()):     # BUILD45: the nodes near the path only
		if id == a or id == b or not box.has_point(layout[id]):
			continue
		var p: Vector2 = layout[id]
		var need: float = (float(_rad[id]) if not _near.is_empty() else _bend_r(id)) + BEND_CLEAR
		for k in range(path.size() - 1):
			var d: float = p.distance_to(Geometry2D.get_closest_point_to_segment(p, path[k], path[k + 1]))
			worst = maxf(worst, need - d)
	return worst


func _bend_r(id: String) -> float:
	var was: bool = assume_pics
	assume_pics = true                    # sized as if its picture had landed: the curve clears it either way
	var r: float = radius_of(node_of(id))
	assume_pics = was
	return r


func _find_bends() -> void:
	_bends = {}
	_bends_for = _layout_sig()
	_index_nodes(_bend_r)
	_find_bends_indexed()
	_near = {}


func _find_bends_indexed() -> void:
	var links: Dictionary = links_all()
	for a in links:
		for b in links[a]:
			if str(a) > str(b) or not layout.has(a) or not layout.has(b):
				continue
			var pa: Vector2 = layout[a]
			var pb: Vector2 = layout[b]
			if _blockers(PackedVector2Array([pa, pb]), str(a), str(b)) <= 0.0:
				continue
			var mid: Vector2 = (pa + pb) / 2.0
			var side: Vector2 = (pb - pa).orthogonal().normalized()
			var best := Vector2.ZERO
			var best_short := INF
			for push in [1.0, 1.5, 2.0, 2.5, 3.0, 4.0]:
				for sgn in [1.0, -1.0]:
					var c: Vector2 = mid + side * sgn * (float(_rad[str(a)]) + BEND_CLEAR) * push * 1.2     # a quadratic peaks half way to its control point
					var short: float = _blockers(_curve(pa, c, pb), str(a), str(b))
					if short < best_short:
						best_short = short
						best = c
				if best_short <= 0.0:
					break
			_bends[str(a) + "|" + str(b)] = _curve(pa, best, pb)


## The names: each at its placed point, centred, a fixed size on screen; the runner's class in the accent.
func _draw_region_names(view: Rect2) -> void:
	for key in _axis:
		var ax: Dictionary = _axis[key]
		if not ax.has("label_at"):
			continue
		var p: Vector2 = to_screen(ax["label_at"])
		if not view.has_point(p):
			continue
		var words: String = region_words(key)
		var w: float = _font_bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE).x
		var tone: Color = ax.get("tone", Pal.TEXT)
		if sim != null and str(key) == "class:" + str(sim.cls):
			tone = Pal.ACCENT
		_text(_font_bold, Vector2(p.x - w / 2.0, p.y + NAME_SIZE * 0.36), words, NAME_SIZE, tone)


## Under everything: the paragon ring's dashed circle round the outside (the ring's own nodes sit on it).
func draw_under(view: Rect2) -> void:
	var c: Vector2 = to_screen(Vector2.ZERO)
	var r: float = R_RING * zoom
	if not view.grow(r).has_point(c):
		return
	var dashes := PackedVector2Array()
	var n: int = maxi(24, int(TAU * r / (2.0 * RING_DASH)))
	for k in range(n):
		var a0: float = TAU * k / n
		var a1: float = a0 + TAU / n * 0.5
		dashes.append(c + Vector2.from_angle(a0) * r)
		dashes.append(c + Vector2.from_angle(a1) * r)
	_tally("lines")
	if not dry:
		draw_multiline(dashes, Color(Pal.ACCENT, 0.28), 1.5, true)


## A node, all from the atlas: owned - a glow, filled and ringed in its colour; can take - an amber ring; not yet - dark,
## its ring a shade of its region's colour. A keystone a diamond, a capstone a bigger one; the big nodes' pictures over
## them (their glyph below PIC_ZOOM); a centre small its stat's letter close in. Its words go to the words' pass.
func _draw_node(id: String, p: Vector2) -> void:
	nodes_drawn += 1
	var nd: Dictionary = node_of(id)
	var st: Dictionary = _state.get(id, {})
	var k: String = str(_kind.get(id, nd.get("web_kind", "small")))
	var tone: Color = _tone.get(id, Pal.TEXT)
	var r: float = radius_of(nd) * zoom
	var z: float = maxf(0.7, zoom)
	var taken: bool = st.get("taken", false)
	var reach: bool = st.get("reach", false)
	var diamond: bool = k == "keystone" or k == "capstone"
	var fill: Color = Pal.BG
	var line: Color = Pal.CARD_LINE.lerp(tone, RING_DIM)
	var w: float = 1.0
	if taken:
		fill = Pal.CARD.lerp(tone, 0.55)
		line = tone
		w = 2.0
		_shape("diamond" if diamond else "disc", p, r * GLOW_R, Color(tone, GLOW))
	elif reach:
		fill = Pal.CARD
		line = FRONTIER
		w = 2.0
	if id == selected:
		line = Pal.TEXT
		w = 3.0
	elif id == hover and not taken:
		line = Pal.TEXT_2
		w = 2.0
	w *= z
	if diamond:
		var o: float = w / 2.0 * sqrt(2.0)          # the outline's half width, along the diagonal
		_shape("diamond", p, r + o, line)
		_shape("diamond", p, maxf(0.5, r - o), fill)
	else:
		_shape("disc", p, r + w / 2.0, line)
		_shape("disc", p, maxf(0.5, r - w / 2.0), fill)
	if big_kind(k):
		var pic: Texture2D = picture(picture_slug(nd))
		if pic != null and zoom >= PIC_ZOOM:
			var g: float = (r - 1.5 * z) * (1.42 if diamond else 1.7)
			var shade: Color = Color(1.25, 1.25, 1.25) if taken else (Color(1.05, 1.05, 1.05) if reach else Color(0.7, 0.7, 0.7))
			_sprite(atlased(pic), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), shade)
		elif glyph_of(nd) != "" and r >= 4.0:
			var g: float = r * 1.1
			_sprite(atlased(NodeGlyphs.texture(glyph_of(nd))), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	elif _region.get(id, "") == "centre" and r >= 6.0:
		var letter: String = stat_letter(id)
		if letter != "":
			var lw: float = _font_bold.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			_text(_font_bold, p + Vector2(-lw / 2.0, 3.5), letter, 9, Pal.BG if taken else Pal.TEXT_2)
	var stack: Array = stack_of(id, nd)
	if not stack.is_empty() and zoom >= 1.0:
		var stack_v: String = "%d/%d" % [int(stack[0]), int(stack[1])]
		var sw: float = _font.get_string_size(stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		_text(_font, p + Vector2(-sw / 2.0, r + 13.0), stack_v, 11, Pal.TEXT if taken else Pal.TEXT_3)
	# the name under a big node, from the label zoom (the hovered and the picked always: under the zoom, on a plate of
	# their own, after the nodes, where it covers the fewest - _draw_pick_labels)
	if zoom < LABEL_ZOOM and (id == hover or id == selected) and big_kind(k) and str(nd.get("name", "")) != "":
		_pick_labels.append([id, p, r, Pal.TEXT if taken or reach else Pal.TEXT_3])
	elif zoom >= LABEL_ZOOM and big_kind(k) and str(nd.get("name", "")) != "":
		var words: String = str(nd["name"])
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_text(_font, p + Vector2(-tw / 2.0, r + 14.0), words, 12, Pal.TEXT if taken or reach else Pal.TEXT_3)


# ------------------------------------------------------------------ input

func node_at(screen_p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		var r: float = maxf(12.0, radius_of(node_of(id)) * zoom) + 4.0
		var d: float = p.distance_to(screen_p)
		if d <= r and d < best_d:
			best_d = d
			best = id
	return best


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
			_drag_from = mb.position
			_cam_from = cam
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom_at(mb.position, ZOOM_STEP)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom_at(mb.position, 1.0 / ZOOM_STEP)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var id := node_at(mb.position)
			pick(id)
			accept_event()
	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event
		if _drag and (mm.button_mask & (MOUSE_BUTTON_MASK_RIGHT | MOUSE_BUTTON_MASK_MIDDLE)) == 0:
			_drag = false                      # released off the canvas (the review): the drag ends with the button
		if _drag:
			cam = _cam_from - (mm.position - _drag_from) / zoom
			queue_redraw()
		else:
			var h := node_at(mm.position)
			if h != hover:
				hover = h
				queue_redraw()


## Zoom about a screen point: the web under the pointer stays under it.
func zoom_at(screen_p: Vector2, by: float) -> void:
	var before: Vector2 = to_web(screen_p)
	zoom = clampf(zoom * by, zoom_min, ZOOM_MAX)
	var after: Vector2 = to_web(screen_p)
	cam += before - after
	queue_redraw()


func pick(id: String) -> void:
	selected = id
	queue_redraw()
	picked.emit(id)


## Pan so a node sits at the view's centre (the screen's "find a node").
func centre_on(id: String) -> void:
	if layout.has(id):
		cam = layout[id]
		zoom = maxf(zoom, 1.4)
		queue_redraw()


## The node whose name starts with (or holds) the words, notables before fillers, or "" (the screen's "find a perk").
func find_named(words: String) -> String:
	var w := words.strip_edges().to_lower()
	if w == "":
		return ""
	var best := ""
	var best_rank := 9
	for id in layout:
		var nd: Dictionary = node_of(id)
		var nm := str(nd.get("name", "")).to_lower()
		var rank := -1
		if nm.begins_with(w):
			rank = 0
		elif nm.contains(w):
			rank = 2
		if rank < 0:
			continue
		if nd.get("filler", false):
			rank += 1
		if rank < best_rank:
			best_rank = rank
			best = id
	return best
