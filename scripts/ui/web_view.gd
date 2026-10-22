extends Control
## The web (22 Oct, docs/design/web.md, the canvas "Fiat – The web"): every tree drawn as a region of one web in
## the Training room's body - the Pitch at the centre, the elements round it, the classes outside - panned with
## the right button, zoomed with the wheel, a node picked with the left. Slice 1: the lanes' nodes as they are,
## laid out along each region's axis; the fillers and the drawn layout come in slice 2.
##
## Signals: `picked(id)` when a node is clicked ("" for a click on nothing).

signal picked(id: String)

const Pal := preload("res://scripts/ui/palette.gd")
const UI := preload("res://scripts/ui/ui.gd")
const Data := preload("res://scripts/sim/data.gd")
const NodeGlyphs := preload("res://scripts/ui/node_glyphs.gd")

const STEP := 80.0                 # a column along a region's axis
const ROW := 26.0                  # a row off the axis
const ZOOM_MIN := 0.18
const ZOOM_MAX := 2.2
const ZOOM_STEP := 1.15
const LABEL_ZOOM := 1.3            # the nodes' names show from here (the cluster zoom); the hovered and the picked always
const R_FILLER := 6.0
const R_PLAIN := 9.0
const R_NOTABLE := 15.0
const R_KEYSTONE := 18.0
const R_CAPSTONE := 22.0
const LINK_W := 2.0
const YARD_TONE := Color("8fb3d9")
## The web lies wide, as the canvas is (slice 1): the Pitch across the centre, three elements' lanes out to the left
## and three to the right, the classes' beyond them. [the entry, the lane's direction].
## Slice 2 (the drawn layout, the canvas "Fiat – The web"): the Pitch across the centre, the elements' lanes out from
## R_ELEMENT at an angle each (a class's pair side by side), the classes' two lanes out from R_CLASS between their
## elements, Data.LANE_OFF rows either side of the angle, their notables hung outward.
const R_ELEMENT := 280.0
const R_CLASS := 740.0
const R_RING := 1300.0             # the paragon ring (slice 4), round the outside
const ELEMENT_LAY := {"Live": -90.0, "Petrol": -30.0, "Blades": 30.0, "Knuckles": 90.0, "The cold": 150.0, "The Rat Man": -150.0}
const CLASS_LAY := {"Drifter": -120.0, "Scrapper": -60.0, "Doorman": 60.0, "Paramedic": 120.0, "Poacher": 180.0}

var sim
var selected := ""
var hover := ""
var cam := Vector2.ZERO            # the web point at the view's centre
var zoom := 1.0
var layout := {}                   # id -> Vector2, web space
var _trees := {}                   # tree name -> its dictionary
var _axis := {}                    # tree name -> {"at": Vector2 (the entry), "dir": Vector2, "tone": Color, "label_at": Vector2}
var _drag := false
var _drag_from := Vector2.ZERO
var _cam_from := Vector2.ZERO
var _state := {}                   # id -> {"taken", "active", "reach", "theirs", "cost"} as last shown
var _state_sig := ""
var _font: Font
var _font_bold: Font
var _bounds := Rect2()


func _init(sz: Vector2) -> void:
	size = sz
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_CLICK
	_font = UI.font("Regular", false)
	_font_bold = UI.font("SemiBold", false)
	lay_out()


# ------------------------------------------------------------------ the layout

## Every tree placed: the Pitch's lane across the centre; an element's lane out along its angle from R_ELEMENT; a
## class's two lanes out along its angle from R_CLASS, either side of the axis. Column c sits c * STEP along the
## axis, row 1 ROW across it.
func lay_out() -> void:
	layout = {}
	_trees = {}
	_axis = {}
	for t in Data.TREES + Data.ELEMENT_TREES + [Data.RING]:
		_trees[t["name"]] = t
	var by_class := {}
	for t in Data.TREES:
		if t.get("class", "") != "":
			if not by_class.has(t["class"]):
				by_class[t["class"]] = []
			by_class[t["class"]].append(t)
	# the Pitch
	var pitch: Dictionary = Data.tree_named(Data.COMMON_TREE)
	_lay_tree(pitch, Vector2(-2.5 * STEP, 0.0), Vector2.RIGHT, Pal.ACCENT)
	for nm in ELEMENT_LAY:
		var t: Dictionary = _trees.get(nm, {})
		if t.is_empty():
			continue
		var d := Vector2.from_angle(deg_to_rad(ELEMENT_LAY[nm]))
		_lay_tree(t, d * R_ELEMENT, d, Pal.ELEMENT_COLOURS.get(t["element"], Pal.TEXT))
	for cls in CLASS_LAY:
		var mine: Array = by_class.get(cls, [])
		var d := Vector2.from_angle(deg_to_rad(CLASS_LAY[cls]))
		for k in range(mine.size()):
			var off: float = (k - (mine.size() - 1) / 2.0) * 2.0 * Data.LANE_OFF * ROW
			_lay_tree(mine[k], d * R_CLASS + d.orthogonal() * off, d, Pal.TEXT)
	# the ring: its nodes round the outside at their angles; the name at the top
	var ring: Dictionary = Data.RING
	for i in range(ring["nodes"].size()):
		layout["%s/%d" % [ring["name"], i]] = Vector2.from_angle(deg_to_rad(float(ring["nodes"][i]["ring"]))) * R_RING
	_axis[ring["name"]] = {"at": Vector2(0, -R_RING), "dir": Vector2.RIGHT, "tone": Pal.ACCENT, "label_at": Vector2(0, -R_RING - 30.0)}
	_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	var first := true
	for id in layout:
		if first:
			_bounds = Rect2(layout[id], Vector2.ZERO)
			first = false
		else:
			_bounds = _bounds.expand(layout[id])
	_bounds = _bounds.grow(90.0)


## A tree's nodes at their built places ("at": columns along the lane, rows across it); the name over the lane's
## middle, above whatever hangs there.
func _lay_tree(t: Dictionary, at: Vector2, dir: Vector2, tone: Color) -> void:
	var side: Vector2 = dir.orthogonal()
	var top: float = 0.0
	for i in range(t["nodes"].size()):
		var nd: Dictionary = t["nodes"][i]
		var a: Array = nd.get("at", [0, 0])
		var p: Vector2 = at + dir * (float(a[0]) * STEP) + side * (float(a[1]) * ROW)
		layout["%s/%d" % [t["name"], i]] = p
		if not nd.has("xlinks"):
			top = minf(top, p.y - at.y)
	# the name: over the Pitch's middle; past the end of a lane that runs out from the centre
	var label_at: Vector2 = at + dir * (2.5 * STEP) + Vector2(0, top - 24.0) if dir == Vector2.RIGHT and at.x < 0.0 else at + dir * (5.0 * STEP + R_CAPSTONE + 34.0)
	_axis[t["name"]] = {"at": at, "dir": dir, "tone": tone, "label_at": label_at}


## A tree's tone: an element's colour, the Pitch's accent, a class's text.
func tone_of(tree_name: String) -> Color:
	return _axis.get(tree_name, {}).get("tone", Pal.TEXT)


# ------------------------------------------------------------------ the camera

func to_screen(p: Vector2) -> Vector2:
	return (p - cam) * zoom + size / 2.0


func to_web(p: Vector2) -> Vector2:
	return (p - size / 2.0) / zoom + cam


## The whole web in the view.
func focus_all() -> void:
	cam = _bounds.get_center()
	zoom = clampf(minf(size.x / _bounds.size.x, size.y / _bounds.size.y), ZOOM_MIN, ZOOM_MAX)
	queue_redraw()


## One tree's region filling the view (a class's two trees together).
func focus_tree(tree_name: String) -> void:
	var names: Array = [tree_name]
	var t: Dictionary = _trees.get(tree_name, {})
	if t.get("class", "") != "":
		names = []
		for other in Data.TREES:
			if other.get("class", "") == t["class"]:
				names.append(other["name"])
	var box := Rect2()
	var first := true
	for id in layout:
		if str(id).get_slice("/", 0) in names:
			if first:
				box = Rect2(layout[id], Vector2.ZERO)
				first = false
			else:
				box = box.expand(layout[id])
	if first:
		return
	box = box.grow(80.0)
	cam = box.get_center()
	zoom = clampf(minf(size.x / box.size.x, size.y / box.size.y), ZOOM_MIN, ZOOM_MAX)
	queue_redraw()


func focus_class(cls: String) -> void:
	for t in Data.TREES:
		if t.get("class", "") == cls:
			focus_tree(t["name"])
			return
	focus_all()


# ------------------------------------------------------------------ the state

func show_state(s) -> void:
	sim = s
	var sig := "%s|%s|%d|%s|%s|%d|%d|%s|%s" % [str(sim.tree), sim.cls, sim.level(), selected, sim.gun_type(), sim.training_points, int(sim.best_level), str(sim.has_rule("headmasters_cap")), str(sim.element_points)]     # the Cap turns every class node active (the review)
	if sig != _state_sig:
		_state_sig = sig
		_state = {}
		var mine: Array = sim.my_classes()
		for id in layout:
			var nd: Dictionary = sim.node(id)
			var taken: bool = sim.tree.has(id)
			var block: String = sim.train_block(id, true) if not taken else ""
			_state[id] = {"taken": taken, "active": taken and sim.node_active(id), "reach": not taken and block == "",
				"theirs": not Data.for_classes(nd, mine), "cost": sim.node_cost(id), "block": block}
	queue_redraw()


func state_of(id: String) -> Dictionary:
	return _state.get(id, {})


# ------------------------------------------------------------------ drawing

static func radius_of(nd: Dictionary) -> float:
	if nd.get("capstone", false):
		return R_CAPSTONE
	if nd.get("keystone", false):
		return R_KEYSTONE
	if nd.get("notable", false):
		return R_NOTABLE
	if nd.get("filler", false):
		return R_FILLER
	return R_PLAIN


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Pal.BG)
	if sim == null:
		return
	var view := Rect2(Vector2.ZERO, size).grow(60.0)
	# the links first, under the nodes: lit between two taken, half-lit to a reachable one, dim otherwise
	var links: Dictionary = Data.web_links_all()
	for a in links:
		for b in links[a]:
			if str(a) > str(b):
				continue              # each pair once (the links run both ways)
			var pa: Vector2 = to_screen(layout[a])
			var pb: Vector2 = to_screen(layout[b])
			if not view.has_point(pa) and not view.has_point(pb):
				continue
			var sa: Dictionary = _state.get(a, {})
			var sb: Dictionary = _state.get(b, {})
			var col: Color = Pal.CARD_LINE
			if sa.get("taken", false) and sb.get("taken", false):
				col = tone_of(str(a).get_slice("/", 0))
			elif (sa.get("taken", false) and sb.get("reach", false)) or (sb.get("taken", false) and sa.get("reach", false)):
				col = Pal.TEXT_2
			draw_line(pa, pb, col, LINK_W * maxf(0.6, zoom), true)
	# the joints: a dashed line between the two halves
	for j in Data.JOINTS:
		var ids: Array = [_joint_half(j["tree"], j["key"]), _joint_half(j["element_tree"], j["key"])]
		if "" in ids:
			continue
		var pa: Vector2 = to_screen(layout[ids[0]])
		var pb: Vector2 = to_screen(layout[ids[1]])
		if view.has_point(pa) or view.has_point(pb):
			var closed: bool = sim.has_joint(j["key"])
			draw_dashed_line(pa, pb, tone_of(j["element_tree"]) if closed else Color(Pal.TEXT_3, 0.6), (3.0 if closed else 1.5) * maxf(0.6, zoom), 8.0)
	# the bridges (slice 3): a dashed line from each to the region it opens, lit when taken
	for id in layout:
		var bn: Dictionary = sim.node(id)
		if not bn.has("bridge"):
			continue
		var to := ""
		for t in Data.TREES:
			if t.get("class", "") == bn["bridge"]:
				to = "%s/0" % t["name"]
				break
		if to == "" or not layout.has(to):
			continue
		var pa: Vector2 = to_screen(layout[id])
		var pb: Vector2 = to_screen(layout[to])
		if view.has_point(pa) or view.has_point(pb):
			var taken_b: bool = _state.get(id, {}).get("taken", false)
			draw_dashed_line(pa, pb, Pal.ACCENT if taken_b else Color(Pal.TEXT_3, 0.5), (3.0 if taken_b else 1.5) * maxf(0.6, zoom), 10.0)
	# the nodes
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		if not view.has_point(p):
			continue
		_draw_node(id, p)
	# the regions' names
	for tn in _axis:
		var p: Vector2 = to_screen(_axis[tn]["label_at"])
		if not view.has_point(p):
			continue
		var t: Dictionary = _trees[tn]
		var words: String = tn
		if t.get("ring", false):
			words = "%s · paragon %d" % [tn, sim.paragon()] + ((" · %d free" % sim.paragon_free()) if sim.paragon_free() > 0 else "")
		elif t.has("element"):
			words = "%s · %s" % [tn, t["element"]]
			var free_v: int = sim.element_free(t["element"])
			if free_v > 0:
				words += " · %d free" % free_v     # the element's own points (slice 3)
			words += " · meter %d%%" % int(round(100.0 * float(sim.element_xp.get(t["element"], 0.0)) / Data.ELEMENT_METER))
		elif t.get("class", "") != "":
			words = "%s · the %s's" % [tn, str(t["class"]).to_lower()]
		else:
			words = "%s · the camp's" % tn
		var fs: int = 15 if zoom >= 0.6 else 13
		var w: float = _font_bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(_font_bold, p - Vector2(w / 2.0, -5.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tone_of(tn))


func _joint_half(tree_name: String, key: String) -> String:
	var t: Dictionary = _trees.get(tree_name, {})
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == key:
			return "%s/%d" % [tree_name, i]
	return ""


func _draw_node(id: String, p: Vector2) -> void:
	var nd: Dictionary = sim.node(id)
	var st: Dictionary = _state.get(id, {})
	var tn: String = id.get_slice("/", 0)
	var tone: Color = tone_of(tn)
	if tn == Data.COMMON_TREE:
		tone = YARD_TONE
	var r: float = radius_of(nd) * zoom
	var taken: bool = st.get("taken", false)
	var reach: bool = st.get("reach", false)
	var theirs: bool = st.get("theirs", false)
	var diamond: bool = nd.get("keystone", false) or nd.get("capstone", false)
	var fill: Color = Pal.BG
	var line: Color = Pal.CARD_LINE
	var w: float = 1.0
	if taken:
		fill = Pal.CARD.lerp(tone, 0.35) if st.get("active", false) else Pal.CARD
		line = tone if st.get("active", false) else Pal.TEXT_3
		w = 2.0
	elif reach:
		fill = Pal.CARD
		line = tone if nd.get("notable", false) or diamond else Pal.TEXT_2
		w = 2.0
	elif theirs:
		fill = Pal.BG
		line = Color(Pal.CARD_LINE, 0.6)
	if id == selected:
		line = Pal.TEXT
		w = 3.0
	elif id == hover and not taken:
		line = Pal.TEXT_2
		w = 2.0
	w *= maxf(0.7, zoom)
	if diamond:
		var pts := PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)])
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, line, w, true)
	else:
		draw_circle(p, r, fill)
		draw_arc(p, r, 0.0, TAU, 32, line, w, true)
	# the glyph, from half zoom
	if zoom >= 0.5 and (nd.get("notable", false) or diamond):
		var tex: Texture2D = NodeGlyphs.texture(NodeGlyphs.of(nd))
		if tex != null:
			var g: float = r * 1.1
			draw_texture_rect(tex, Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), false, tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	if nd.has("ring") and zoom >= 0.6:
		var stack_v: String = "%d/%d" % [int(sim.ring.get(id, 0)), int(nd["stack"])]
		var sw: float = _font.get_string_size(stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		draw_string(_font, p + Vector2(-sw / 2.0, r + 13.0), stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT if taken else Pal.TEXT_3)
	# the name under a notable, the keystone's level by it, from the label zoom
	if (zoom >= LABEL_ZOOM or id == hover or id == selected) and (nd.get("notable", false) or diamond):
		var fs: int = 12
		var words: String = str(nd["name"])
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(_font, p + Vector2(-tw / 2.0, r + 14.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.TEXT if taken or reach else Pal.TEXT_3)
	if diamond and not taken and not theirs and zoom >= 0.6:
		var at: int = Data.KEYSTONE_LEVEL if nd.get("keystone", false) else Data.CAPSTONE_LEVEL
		var lv: String = "Lv %d" % at
		draw_string(_font, p + Vector2(r + 6.0, -r + 4.0), lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.GOOD if sim.level() >= at else Pal.TEXT_3)


# ------------------------------------------------------------------ input

func node_at(screen_p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		var r: float = maxf(12.0, radius_of(sim.node(id)) * zoom) + 4.0
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
	zoom = clampf(zoom * by, ZOOM_MIN, ZOOM_MAX)
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
		zoom = maxf(zoom, 1.0)
		queue_redraw()


## The node whose name starts with (or holds) the words, notables before fillers, or "" (the screen's "find a perk").
func find_named(words: String) -> String:
	var w := words.strip_edges().to_lower()
	if w == "":
		return ""
	var best := ""
	var best_rank := 9
	for id in layout:
		var nd: Dictionary = sim.node(id)
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
