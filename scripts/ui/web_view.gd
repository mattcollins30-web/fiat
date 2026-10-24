extends Control
## The web (22 Oct, docs/design/web.md, the canvas "Fiat – The web"): every tree drawn as a region of one web in
## the Training room's body - the Pitch at the centre, the elements round it, the classes outside - panned with
## the right button, zoomed with the wheel, a node picked with the left. Slice 1: the lanes' nodes as they are,
## laid out along each region's axis; the fillers and the drawn layout come in slice 2.
##
## Signals: `picked(id)` when a node is clicked ("" for a click on nothing).
##
## Slice 4 (web_map_pitch.md §3): the canvas is a base - the camera, the drawing, the input - with the web it draws
## behind hooks (node_of, links_all, lay_out, state_for, state_sig, region_words, stack_of, draw_between); Training's
## web is the default, the Map's (map_web.gd) and the Pitch's (yard_web.gd) override them.

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
const LINK_DIM := Color("4a5059")       # a link to nothing reached yet (23 Oct: CARD_LINE was lost on the backdrop and the lit disc)
const LINK_LIT_DIM := Color("7a8290")   # the same inside the class's lit wheel (Matt: "far too faint and really hard to read")
## The elements' regions in their colour (23 Oct, Matt: "the coloured boxes for the elements just look cheap - the
## lines and node outlines should carry the element's colour instead"): no hull; a link between two of its nodes in
## its colour at ELEMENT_LINK_DIM, lighter where it reaches, whole where both are taken; a ring its colour mixed in
## at ELEMENT_RING_DIM, whole once reachable or taken.
const ELEMENT_HULLS := false
## The Pitch its own (23 Oct, Matt: "square sand + portraits"): the camp's tree built, not grown - square nodes, its
## links and rings in PITCH_TONE as the elements' in theirs, its emblem the hub on its starting node.
const PITCH_TONE := Color("d1a65f")       # sand: apart from The cold's blue and softer than the class's amber
## And the class's portrait faint under its lit wheel, faded out before the rim.
const PORTRAIT_SHADE := Color(0.75, 0.72, 0.68, 0.16)
const ELEMENT_LINK_DIM := 0.5
const ELEMENT_RING_DIM := 0.55
## The web lies wide, as the canvas is (slice 1): the Pitch across the centre, three elements' lanes out to the left
## and three to the right, the classes' beyond them. [the entry, the lane's direction].
## Slice 2 (the drawn layout, the canvas "Fiat – The web"): the Pitch across the centre, the elements' lanes out from
## R_ELEMENT at an angle each (a class's pair side by side), the classes' two lanes out from R_CLASS between their
## elements, Data.LANE_OFF rows either side of the angle, their notables hung outward.
const R_ELEMENT := 280.0
const R_CLASS := 740.0
## The wheel (23 Oct, the canvas pass; Data.WHEEL_*): a class's two lanes round one ring whose centre sits WHEEL_OUT
## past R_CLASS along the class's angle, the starter at the near pole; the first lane runs round one way, the second
## the other. The class on show has a warm disc under its wheel; each element's region a hull in its colour.
const WHEEL_OUT := 3.4 * STEP
const WHEEL_GLOW := 1.3 * STEP     # the disc past the tracks
const R_NOTABLE_PIC := 17.0        # a notable's disc with a picture in it (the art, 23 Oct: 15 read as a blob)
const PIC_ZOOM := 0.5              # the pictures draw from here; the glyph before (and where no picture is). 0.8 till 23 Oct (Matt: the glyphs read worse than a small picture)
const R_SMALL_PIC := 13.0         # a small node with a picture (23 Oct, Matt: art in every node): 9 can't hold a painting
const R_FILLER_PIC := 10.0        # a filler with one: drawn from FILLER_PIC_ZOOM, a dot before
const FILLER_PIC_ZOOM := 0.9
static var assume_pics := false   # the smoke: every node sized as if its picture had landed, so the overlap checks hold before the art does
const R_ENTRY := 20.0
const ENTRY_LABEL_ZOOM := 0.8     # the names move from the rim to the starters from here (23 Oct; 0.6 boxed the cold's name 150 px off its starter)              # a class's entry node, with the class's emblem on it (23 Oct, Matt: "so it's clear where each class's journey starts")
const R_RING := 1480.0             # the paragon ring (slice 4), round the outside (1300 to 1480, 23 Oct: outside the wheels)
const ELEMENT_LAY := {"Live": -90.0, "Petrol": -30.0, "Blades": 30.0, "Knuckles": 90.0, "The cold": 150.0, "The Rat Man": -150.0}
const CLASS_LAY := {"Drifter": -120.0, "Scrapper": -60.0, "Recruit": 0.0, "Doorman": 60.0, "Paramedic": 120.0, "Poacher": 180.0}     # the Recruit on the free spoke (24 Oct, milestone 8)

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
var _focused := false              # the first show frames the whole web
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
			_lay_wheel(mine[k], cls, d, CLASS_LAY[cls])
	# the ring: its nodes round the outside at their angles; the name at the top
	var ring: Dictionary = Data.RING
	for i in range(ring["nodes"].size()):
		layout["%s/%d" % [ring["name"], i]] = Vector2.from_angle(deg_to_rad(float(ring["nodes"][i]["ring"]))) * R_RING
	_axis[ring["name"]] = {"at": Vector2(0, -R_RING), "dir": Vector2.RIGHT, "tone": Pal.ACCENT, "label_at": Vector2.from_angle(deg_to_rad(30.0)) * (R_RING + 30.0), "align": 1}     # between the Recruit and the Doorman, where no class sits (24 Oct: the right is the Recruit's now)
	_find_bounds()
	_labels_by_entry()


## Every region's name by its first node (23 Oct, Matt: "the naming for every tree class/element/pitch needs to sit by
## their first node"): the label goes beside the region's one starter - below it, above, right or left, the first of
## those (and then a step further out) whose words cover no node and no name already placed, at full zoom's size.
func _labels_by_entry() -> void:
	var placed: Array = []
	for tn in _axis:
		if _axis[tn].get("hide_label", false) or not _trees.has(tn) or _trees[tn].get("ring", false):
			continue
		var t: Dictionary = _trees[tn]
		var entry_id := ""
		for i in range(t["nodes"].size()):
			if t["nodes"][i].get("entry", false):
				entry_id = "%s/%d" % [tn, i]
				break
		if entry_id == "" or not layout.has(entry_id):
			continue
		var p: Vector2 = layout[entry_id]
		var r: float = radius_of(node_of(entry_id)) if sim != null else R_ENTRY
		var words: String = region_words(tn) if sim != null else tn
		# the words are a fixed screen size, so they're measured at the closest zoom they show at (the review): there a
		# screen pixel is 1/ENTRY_LABEL_ZOOM of the web's; further in they only take less
		var k: float = 1.0 / ENTRY_LABEL_ZOOM
		var es: float = EMBLEM * 0.7 if str(_axis[tn].get("class", "")) == "" else 0.0     # the emblem as drawn at that zoom (clamped to 0.7)
		var w: float = (_font_bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + (es + 6.0 if es > 0.0 else 0.0)) * k
		var top: float = maxf(14.0, es / 2.0 + 8.0) * k        # above the anchor: the cap height, or the emblem's top
		var foot: float = maxf(10.0, es / 2.0 - 4.0) * k        # below it: the descenders, or the emblem's foot
		var gap: float = 10.0 * k
		var best: Array = []
		for far in [0.0, 18.0, 36.0, 60.0, 90.0, 130.0]:
			var f: float = far * k
			var d: float = (r + gap + f) * 0.72               # the diagonals: the corner of the words nearest the node
			for c in [[Vector2(0, r + gap + top + f), 0], [Vector2(0, -r - gap - foot - f), 0], [Vector2(r + gap + f, 0), 1], [Vector2(-r - gap - f, 0), -1],
					[Vector2(d, d + top), 1], [Vector2(-d, d + top), -1], [Vector2(d, -d - foot), 1], [Vector2(-d, -d - foot), -1]]:
				var at: Vector2 = p + c[0]
				var al: int = c[1]
				var x0: float = at.x - w if al < 0 else (at.x if al > 0 else at.x - w / 2.0)
				var box := Rect2(x0, at.y - top, w, top + foot)
				if _label_clear(box, placed):
					best = [at, al, box]
					break
			if not best.is_empty():
				break
		if best.is_empty():
			var at0: Vector2 = p + Vector2(0, r + gap + top)
			best = [at0, 0, Rect2(at0.x - w / 2.0, at0.y - top, w, top + foot)]
		if not _axis[tn].has("rim_at"):
			_axis[tn]["rim_at"] = _axis[tn]["label_at"]           # the rim's place, for the whole web (below)
			_axis[tn]["rim_align"] = int(_axis[tn].get("align", 0))
		_axis[tn]["entry_at"] = best[0]
		_axis[tn]["entry_align"] = best[1]
		_axis[tn]["label_box"] = best[2]
		placed.append(best[2])


## A region's name on screen as it's drawn at this zoom (for the smoke): the words and the emblem, by the starter -
## or, `rim`, at its place for the whole web (24 Oct: the ring's sat on the Recruit's).
func entry_label_rect(tn: String, rim := false) -> Rect2:
	var ax: Dictionary = _axis.get(tn, {})
	if not ax.has("entry_at") and not rim:
		return Rect2()
	var p: Vector2 = to_screen(ax.get("rim_at", ax.get("label_at", Vector2.ZERO)) if rim else ax["entry_at"])
	var fs: int = 15 if zoom >= 0.6 else 13
	var w: float = _font_bold.get_string_size(region_words(tn), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var es: float = EMBLEM * clampf(zoom, 0.7, 1.2) if str(ax.get("class", "")) == "" and tn != Data.COMMON_TREE and emblem_of(tn) != null else 0.0
	var full: float = w + (es + 6.0 if es > 0.0 else 0.0)
	var al: int = int(ax.get("rim_align", ax.get("align", 0))) if rim else int(ax.get("entry_align", 0))
	var x0: float = p.x - full if al < 0 else (p.x if al > 0 else p.x - full / 2.0)
	var top: float = maxf(fs * 0.8, es / 2.0 + 7.0)
	var foot: float = maxf(fs * 0.3, es / 2.0 - 5.0)
	return Rect2(x0, p.y - top, full, top + foot)


func _label_clear(box: Rect2, placed: Array) -> bool:
	for b in placed:
		if box.intersects(b):
			return false
	for id in layout:
		var q: Vector2 = layout[id]
		var rr: float = (radius_of(node_of(id)) if sim != null else R_PLAIN) + 2.0
		if box.grow(rr).has_point(q):
			return false
	return true


func _find_bounds() -> void:
	_bounds = Rect2(Vector2.ZERO, Vector2.ZERO)
	var first := true
	for id in layout:
		if first:
			_bounds = Rect2(layout[id], Vector2.ZERO)
			first = false
		else:
			_bounds = _bounds.expand(layout[id])
	_bounds = _bounds.grow(90.0)


# ------------------------------------------------------------------ the hooks (Training's web by default)

func node_of(id: String) -> Dictionary:
	return sim.node(id)


func links_all() -> Dictionary:
	return Data.web_links_all()


## The signature of what the state reads: a change relays the state.
func state_sig() -> String:
	return "%s|%s|%d|%s|%s|%d|%d|%s|%s" % [str(sim.tree), sim.cls, sim.level(), selected, sim.gun_type(), sim.training_points, int(sim.best_level), str(sim.has_rule("headmasters_cap")), str(sim.element_points)]     # the Cap turns every class node active (the review)


## A node's state as drawn: taken, active, reach (open to train now, the points aside), theirs (another class's), cost, block.
func state_for(id: String) -> Dictionary:
	var nd: Dictionary = sim.node(id)
	var taken: bool = sim.tree.has(id)
	var block: String = sim.train_block(id, true) if not taken else ""
	return {"taken": taken, "active": taken and sim.node_active(id), "reach": not taken and block == "",
		"theirs": not Data.for_classes(nd, sim.my_classes()), "cost": sim.node_cost(id), "block": block}


## A node's points on it of its stack, [n, top], or [] for a plain node.
func stack_of(id: String, nd: Dictionary) -> Array:
	if nd.has("ring"):
		return [int(sim.ring.get(id, 0)), int(nd["stack"])]
	return []


## A region's name over it.
func region_words(tn: String) -> String:
	var t: Dictionary = _trees[tn]
	if t.get("ring", false):
		return "%s · paragon %d" % [tn, sim.paragon()]     # its free points are the key's (23 Oct)
	if t.has("element"):
		return "%s · %s" % [tn, t["element"]]     # the name alone: the meter and the free points are the key's (23 Oct, Matt)
	if t.get("class", "") != "":
		var lanes: Array = []
		for other in Data.TREES:
			if other.get("class", "") == t["class"]:
				lanes.append(str(other["name"]))
		return "%s · %s" % [str(t["class"]), " and ".join(lanes)]
	return "%s · the Yard" % tn                   # the glossary: never "camp" (the language pass)


## A node's glyph key (node_glyphs.gd), or "" for none.
func glyph_of(nd: Dictionary) -> String:
	return NodeGlyphs.of(nd)


## A node's level tag (Training's keystones and capstones) as [words, met], or [].
func level_tag(nd: Dictionary) -> Array:
	if nd.get("keystone", false) or nd.get("capstone", false):
		var at: int = Data.KEYSTONE_LEVEL if nd.get("keystone", false) else Data.CAPSTONE_LEVEL
		return ["Lv %d" % at, sim.level() >= at]
	return []


## What's drawn between the links and the nodes: Training's joints and bridges.
func draw_between(view: Rect2) -> void:
	for j in Data.JOINTS:
		var ids: Array = [_joint_half(j["tree"], j["key"]), _joint_half(j["element_tree"], j["key"])]
		if "" in ids:
			continue
		var pa: Vector2 = to_screen(layout[ids[0]])
		var pb: Vector2 = to_screen(layout[ids[1]])
		if view.has_point(pa) or view.has_point(pb):
			var closed: bool = sim.has_joint(j["key"])
			var tone: Color = tone_of(j["element_tree"])     # the element's colour, closed or open (23 Oct: the join lines coloured too)
			_tally("lines")
			if not dry:
				draw_dashed_line(pa, pb, tone if closed else Color(tone, 0.55), (3.0 if closed else 1.5) * maxf(0.6, zoom), 8.0)
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
			_tally("lines")
			if not dry:
				draw_dashed_line(pa, pb, Pal.ACCENT if taken_b else Color(Pal.TEXT_3, 0.5), (3.0 if taken_b else 1.5) * maxf(0.6, zoom), 10.0)


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


## A class lane on its half of the class's wheel: a node's "wheel" [degrees along the half, radius in rows] turned
## into a point - the half's degrees run from the near pole (facing the centre) round, the first lane one way and
## the second the other. The class's name past the far pole, once (the first lane's label; the second's hidden).
func _lay_wheel(t: Dictionary, cls: String, d: Vector2, deg: float) -> void:
	var centre: Vector2 = d * (R_CLASS + WHEEL_OUT)
	var sgn: float = -1.0 if int(t.get("lane", 0)) == 0 else 1.0
	for i in range(t["nodes"].size()):
		var nd: Dictionary = t["nodes"][i]
		var w: Array = nd.get("wheel", [0.0, Data.WHEEL_R])
		var a: float = deg + 180.0 + sgn * float(w[0])
		layout["%s/%d" % [t["name"], i]] = centre + Vector2.from_angle(deg_to_rad(a)) * (float(w[1]) * ROW)
	var label_at: Vector2 = centre + d * ((Data.WHEEL_R + Data.WHEEL_TRACK / 2.0 + Data.WHEEL_HANG) * ROW + 44.0)
	_axis[t["name"]] = {"at": centre - d * (Data.WHEEL_R * ROW), "dir": d, "tone": Pal.TEXT, "label_at": label_at, "wheel": centre, "class": cls,
		"align": (-1 if d.x < -0.3 else (1 if d.x > 0.3 else 0)), "hide_label": int(t.get("lane", 0)) != 0}


## A tree's tone: an element's colour, the Pitch's accent, a class's text.
func tone_of(tree_name: String) -> Color:
	if tree_name == Data.COMMON_TREE:
		return PITCH_TONE
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

var _labels_sim := false
func show_state(s) -> void:
	sim = s
	if not _labels_sim:
		_labels_sim = true
		_labels_by_entry()                   # again with the sim: the real radii and the words as drawn
		_pack_all()
	if not _focused:
		_focused = true
		focus_all()
	var sig := state_sig()
	if sig != _state_sig:
		_state_sig = sig
		_state = {}
		for id in layout:
			_state[id] = state_for(id)
	queue_redraw()


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
	return slug_of(str(nd.get("name", "")))


static var _slugs := {}
static func slug_of(words: String) -> String:
	if _slugs.has(words):
		return _slugs[words]                  # built once a name (the review: every node, every redraw and hover)
	var out := ""
	var gap := false
	for ch in words.to_lower():
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			if gap and out != "":
				out += "_"
			gap = false
			out += ch
		else:
			gap = true
	_slugs[words] = out
	return out


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


## Everything this canvas can draw packed at once, on its first show (the review): packed lazily, a pan across the
## web packed a few pictures a frame and sent the whole atlas up on each of them.
func _pack_all() -> void:
	for kind in ["disc", "diamond", "square"]:
		for n in DISC_SIZES:
			shape(kind, n / 2.0)
	for tn in _trees:
		if _trees[tn].has("class"):
			atlased(wheel_portrait(str(_trees[tn]["class"])))
	for id in layout:
		var nd: Dictionary = node_of(id)
		atlased(picture(picture_slug(nd)))
		if glyph_of(nd) != "":
			atlased(NodeGlyphs.texture(glyph_of(nd)))
	for tn in _axis:
		atlased(emblem_of(tn))
	_atlas_flush()
	_ensure_bends()                        # the curved links worked here too, not on a pan's first frame


## The atlas's new cells sent up, once a frame at most (the pictures land on the first draws, then never again).
static func _atlas_flush() -> void:
	if _atlas_dirty and _atlas_tex != null:
		_atlas_tex.update(_atlas_img)
		_atlas_dirty = false


## The canvas's backdrop (23 Oct, the manifest): art/web/backdrop_<slug>.png under everything, covering the view.
## Training's is "training"; the Map's and the Pitch's name their own.
func backdrop_slug() -> String:
	return "training"


## The class's portrait for under its lit wheel (23 Oct): art/people/<class>.png, faded to nothing at its
## rim, made once.
static var _portraits := {}
static func wheel_portrait(cls: String) -> Texture2D:
	if _portraits.has(cls):
		return _portraits[cls]
	var tex: Texture2D = art_at("res://art/people_new/%s.png" % cls.to_lower())     # the new face first, as the card's (24 Oct: the Recruit's is only there)
	if tex == null:
		tex = art_at("res://art/people/%s.png" % cls.to_lower())
	var out: Texture2D = null
	if tex != null:
		var img: Image = tex.get_image()
		if img != null and not img.is_empty():
			img = img.duplicate()
			if img.is_compressed():
				img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			var n := img.get_width()
			for y in range(img.get_height()):
				for x in range(n):
					var d: float = Vector2(x + 0.5 - n / 2.0, y + 0.5 - img.get_height() / 2.0).length() / (n / 2.0)
					var c: Color = img.get_pixel(x, y)
					c.a *= clampf((1.0 - d) / 0.35, 0.0, 1.0)
					img.set_pixel(x, y, c)
			out = ImageTexture.create_from_image(img)
	_portraits[cls] = out
	return out


## Whether a region is the class on show's (its wheel lit).
## A region drawn in its own colour (its links and rings): an element's, and the Pitch's.
func tinted(tn: String) -> bool:
	return _trees.get(tn, {}).has("element") or tn == Data.COMMON_TREE


func _lit_wheel(tn: String) -> bool:
	return str(_trees.get(tn, {}).get("class", "")) != "" and str(_trees[tn]["class"]) == str(sim.cls)


## A region's emblem beside its label (23 Oct, the manifest): art/web/region_<slug>.png, drawn EMBLEM tall.
const EMBLEM := 26.0
func emblem_of(tn: String) -> Texture2D:
	return art_at("res://art/web/region_%s.png" % slug_of(tn))


func radius_of(nd: Dictionary) -> float:
	var diamond: bool = nd.get("keystone", false) or nd.get("capstone", false)
	var pictured: bool = assume_pics or picture(picture_slug(nd)) != null
	if nd.get("entry", false) and entry_emblem(nd) != null:
		return R_ENTRY
	if pictured and not diamond:
		if nd.get("notable", false):
			return R_NOTABLE_PIC
		if nd.get("filler", false):
			return R_FILLER_PIC if assume_pics or zoom >= FILLER_PIC_ZOOM else R_FILLER     # a dot below its picture's zoom stays a dot's size (the review)
		return R_SMALL_PIC
	return _radius_plain(nd)


## A class's entry node carries the class's emblem (23 Oct): the first lane's region emblem, moved off the rim label.
func entry_emblem(nd: Dictionary) -> Texture2D:
	var tn: String = str(nd.get("region", ""))
	if tn == Data.COMMON_TREE:
		return emblem_of(tn)
	if tn == "" or not _trees.has(tn) or not _trees[tn].has("class"):
		return null
	return emblem_of(tn)


static func _radius_plain(nd: Dictionary) -> float:
	if nd.get("capstone", false):
		return R_CAPSTONE
	if nd.get("keystone", false):
		return R_KEYSTONE
	if nd.get("notable", false):
		return R_NOTABLE
	if nd.get("filler", false):
		return R_FILLER
	return R_PLAIN


## The frame in passes (23 Oct, the fans): the backdrop and the hulls; the links, one call a colour; the joins; every
## node's disc, ring and picture from the atlas, one call; the regions' emblems from it too; then the words, grouped by
## font and size. `batches` counts the calls as the canvas issues them (the smoke holds it under BATCH_MAX).
const BATCH_MAX := 60
var batches := 0
var dry := false                       # the smoke: the frame's passes run and count, nothing drawn (it never draws headless)
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


func _draw() -> void:
	batches = 0
	_batch_key = ""
	_texts = {}
	_tally("")
	if not dry:
		draw_rect(Rect2(Vector2.ZERO, size), Pal.BG)
	var bd: Texture2D = art_at("res://art/web/backdrop_%s.png" % backdrop_slug())
	if bd != null:
		# the backdrop covers the canvas whole, its proportions kept (the painting's 744 wide at the API's most)
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
	_draw_region_names(view)
	# the words last, a font and size at a time
	for key in _texts:
		_tally("text:" + key)
		for t in _texts[key]:
			if not dry:
				draw_string(t[0], t[1], t[2], HORIZONTAL_ALIGNMENT_LEFT, -1, t[3], t[4])
	_texts = {}
	_atlas_flush()


## The links, under the nodes: lit between two taken, half-lit to a reachable one, dim otherwise; gathered by colour
## and width, one draw_multiline each.
func _draw_links(view: Rect2) -> void:
	var runs := {}                         # [colour, width] -> PackedVector2Array of pairs
	_ensure_bends()
	var links: Dictionary = links_all()
	for a in links:
		for b in links[a]:
			if str(a) > str(b):
				continue              # each pair once (the links run both ways)
			var pa: Vector2 = to_screen(layout[a])
			var pb: Vector2 = to_screen(layout[b])
			if not view.has_point(pa) and not view.has_point(pb):
				continue
			var lit: bool = _lit_wheel(str(a).get_slice("/", 0))     # inside the class's lit wheel the dim links read brighter and thicker (23 Oct)
			var run := [link_colour(str(a), str(b)), LINK_W * (1.4 if lit else 1.0) * maxf(0.6, zoom)]
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


## An element's reachable link and ring: its colour lighter, or darker where the colour's near white already (the
## review: Knuckles' is Pal.TEXT, and lighter read the same as taken).
static func reach_tone(tone: Color) -> Color:
	return tone.lerp(Color.WHITE, 0.4) if tone.get_luminance() < 0.7 else tone.darkened(0.35)


## A link's colour: lit between two taken, half-lit to a reachable one, dim otherwise; inside an element's region its
## colour throughout (23 Oct).
func link_colour(a: String, b: String) -> Color:
	var sa: Dictionary = _state.get(a, {})
	var sb: Dictionary = _state.get(b, {})
	var ta: String = a.get_slice("/", 0)
	var elem: bool = tinted(ta) and ta == b.get_slice("/", 0)
	if sa.get("taken", false) and sb.get("taken", false):
		return tone_of(ta)
	if (sa.get("taken", false) and sb.get("reach", false)) or (sb.get("taken", false) and sa.get("reach", false)):
		return reach_tone(tone_of(ta)) if elem else Pal.TEXT
	if elem:
		return Color(tone_of(ta), ELEMENT_LINK_DIM)
	return LINK_LIT_DIM if _lit_wheel(ta) else LINK_DIM


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
	for id in layout:
		if id == a or id == b or not box.has_point(layout[id]):
			continue
		var p: Vector2 = layout[id]
		var need: float = _bend_r(id) + BEND_CLEAR
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
					var c: Vector2 = mid + side * sgn * (_bend_r(str(a)) + BEND_CLEAR) * push * 1.2     # a quadratic peaks half way to its control point
					var short: float = _blockers(_curve(pa, c, pb), str(a), str(b))
					if short < best_short:
						best_short = short
						best = c
				if best_short <= 0.0:
					break
			_bends[str(a) + "|" + str(b)] = _curve(pa, best, pb)


## The regions' names: by the region's first node from ENTRY_LABEL_ZOOM (a region's or a class's view); on the rim at
## the whole web, where twelve starters round the centre would put twelve names on each other (23 Oct).
func _draw_region_names(view: Rect2) -> void:
	for tn in _axis:
		if _axis[tn].get("hide_label", false):
			continue
		var by_entry: bool = zoom >= ENTRY_LABEL_ZOOM and _axis[tn].has("entry_at")
		var p: Vector2 = to_screen(_axis[tn]["entry_at"] if by_entry else _axis[tn].get("rim_at", _axis[tn]["label_at"]))
		if not view.has_point(p):
			continue
		var words: String = region_words(tn)
		var fs: int = 15 if zoom >= 0.6 else 13
		var w: float = _font_bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var align: int = int(_axis[tn]["entry_align"] if by_entry else _axis[tn].get("rim_align", _axis[tn].get("align", 0)))     # -1: the words end at the point; 1: start there; 0: centred
		var em: Texture2D = emblem_of(tn) if str(_axis[tn].get("class", "")) == "" and tn != Data.COMMON_TREE else null     # a class's emblem is on its entry node, the Pitch's on its hub (23 Oct)
		var es: float = EMBLEM * clampf(zoom, 0.7, 1.2) if em != null else 0.0
		var full: float = w + (es + 6.0 if em != null else 0.0)     # the emblem leads the words
		var x0: float = p.x - full if align < 0 else (p.x if align > 0 else p.x - full / 2.0)
		var tone: Color = Pal.ACCENT if str(_axis[tn].get("class", "")) != "" and str(_axis[tn]["class"]) == str(sim.cls) else tone_of(tn)
		if em != null:
			_sprite(atlased(em), Rect2(x0, p.y + 5.0 - fs * 0.78 - (es - fs) / 2.0, es, es))
			x0 += es + 6.0
		_text(_font_bold, Vector2(x0, p.y + 5.0), words, fs, tone)


## Under everything (23 Oct, the canvas pass): a warm disc under the wheel of the class on show, so you know where
## you're starting from; each element's region in a hull of its colour - a faint wash, a line - so it reads at a glance.
func draw_under(view: Rect2) -> void:
	for tn in _axis:
		var ax: Dictionary = _axis[tn]
		if ax.has("wheel") and not ax.get("hide_label", false) and str(ax.get("class", "")) == str(sim.cls):
			var c: Vector2 = to_screen(ax["wheel"])
			var r: float = ((Data.WHEEL_R + Data.WHEEL_TRACK / 2.0) * ROW + WHEEL_GLOW) * zoom
			if view.grow(r).has_point(c):
				for k in range(3):
					_tally("")                     # two discs and a ring, a call each
				if not dry:
					draw_circle(c, r, Color(Pal.BG, 0.55))        # darker than the links, not warmer (23 Oct: the warm wash lost the lines)
					draw_circle(c, r, Color(Pal.ACCENT, 0.04))
				var face: Texture2D = atlased(wheel_portrait(str(sim.cls)))
				if face != null:
					_sprite(face, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), PORTRAIT_SHADE)
				if not dry:
					draw_arc(c, r, 0.0, TAU, 96, Color(Pal.ACCENT, 0.3), 1.5, true)
	for tn in _trees:
		var t: Dictionary = _trees[tn]
		if not ELEMENT_HULLS or not t.has("element"):
			continue
		var box := Rect2()
		var first := true
		for i in range(t["nodes"].size()):
			var p: Vector2 = layout["%s/%d" % [tn, i]]
			box = Rect2(p, Vector2.ZERO) if first else box.expand(p)
			first = false
		var d: Vector2 = _axis[tn]["dir"]
		var tone: Color = tone_of(tn)
		# the hull: a capsule along the lane's axis, the nodes' extent plus a margin, drawn as a rotated rounded rect
		var along: float = 0.0
		var across: float = 0.0
		var centre: Vector2 = box.get_center()
		for i in range(t["nodes"].size()):
			var q: Vector2 = layout["%s/%d" % [tn, i]] - centre
			along = maxf(along, absf(q.dot(d)))
			across = maxf(across, absf(q.dot(d.orthogonal())))
		var sc: Vector2 = to_screen(centre)
		if not view.grow((along + 60.0) * zoom).has_point(sc):
			continue
		var hw: float = (along + 0.6 * STEP) * zoom
		var hh: float = (across + 0.9 * ROW) * zoom
		var pts := PackedVector2Array()
		var rr: float = minf(hh, 18.0 * zoom)
		for k in range(4):
			var cx: float = (hw - rr) * (1.0 if k in [0, 1] else -1.0)
			var cy: float = (hh - rr) * (1.0 if k in [1, 2] else -1.0)
			var a0: float = [-PI / 2.0, 0.0, PI / 2.0, PI][k]
			for j in range(7):
				var a: float = a0 + j * (PI / 2.0) / 6.0
				pts.append(sc + (Vector2(cx, cy) + Vector2(cos(a), sin(a)) * rr).rotated(d.angle()))
		_tally("")
		_tally("")                             # the wash and the line
		if not dry:
			draw_colored_polygon(pts, Color(tone, 0.05))
			pts.append(pts[0])
			draw_polyline(pts, Color(tone, 0.6), 1.4 * maxf(0.7, zoom), true)


func _joint_half(tree_name: String, key: String) -> String:
	var t: Dictionary = _trees.get(tree_name, {})
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == key:
			return "%s/%d" % [tree_name, i]
	return ""


## A node, all from the atlas: the ring as a disc of the line's colour under the fill's (the arc's width either side of
## the radius, as draw_arc drew it), the picture or the glyph over; its words go to the words' pass.
func _draw_node(id: String, p: Vector2) -> void:
	var nd: Dictionary = node_of(id)
	var st: Dictionary = _state.get(id, {})
	var tn: String = id.get_slice("/", 0)
	var tone: Color = tone_of(tn)
	var r: float = radius_of(nd) * zoom
	var taken: bool = st.get("taken", false)
	var reach: bool = st.get("reach", false)
	var theirs: bool = st.get("theirs", false)
	var diamond: bool = nd.get("keystone", false) or nd.get("capstone", false)
	var fill: Color = Pal.BG
	var line: Color = Pal.CARD_LINE
	var w: float = 1.0
	var elem: bool = tinted(tn)          # an element's rings carry its colour (23 Oct, Matt: the boxes "look cheap"), the Pitch's too
	if elem:
		line = Pal.CARD_LINE.lerp(tone, ELEMENT_RING_DIM)
	if taken:
		fill = Pal.CARD.lerp(tone, 0.35) if st.get("active", false) else Pal.CARD
		line = tone if st.get("active", false) else (Pal.CARD_LINE.lerp(tone, ELEMENT_RING_DIM) if elem else Pal.TEXT_3)     # an element's trained-but-idle node keeps the dim ring (the review: another class's half, a gun not in hand)
		w = 2.0
	elif reach:
		fill = Pal.CARD
		line = reach_tone(tone) if elem else (tone if nd.get("notable", false) or diamond else Pal.TEXT_2)     # an element's reachable ring apart from its taken ones, as its links
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
		var o: float = w / 2.0 * sqrt(2.0)          # the outline's half width, along the diagonal
		_shape("diamond", p, r + o, line)
		_shape("diamond", p, r - o, fill)
	elif tn == Data.COMMON_TREE:
		_shape("square", p, r * 0.9 + w / 2.0, line)     # the Pitch's nodes built, not grown (23 Oct)
		_shape("square", p, r * 0.9 - w / 2.0, fill)
	else:
		if nd.has("skill"):
			# a skill (24 Oct, milestone 8; skills.md §3): its own ring outside the node's, in the energy colour - dim until
			# it's reached, full once trained
			var z: float = maxf(0.7, zoom)
			_shape("disc", p, r + w / 2.0 + 4.0 * z, Pal.ENERGY if taken else (Pal.ENERGY.lerp(Pal.BG, 0.25) if reach else Pal.ENERGY.lerp(Pal.BG, 0.6)))
			_shape("disc", p, r + w / 2.0 + 2.0 * z, Pal.BG)
		_shape("disc", p, r + w / 2.0, line)
		_shape("disc", p, r - w / 2.0, fill)
	# the picture across the disc from PIC_ZOOM (23 Oct, the art), dimmed until it's reached; else the glyph from half zoom
	var pic: Texture2D = picture(picture_slug(nd))          # every node with a picture draws it (23 Oct; notables and diamonds only before)
	if nd.get("entry", false) and tn == Data.COMMON_TREE:
		pic = emblem_of(tn)                     # the Pitch's emblem its hub (23 Oct)
	if pic == null and nd.get("entry", false) and _trees.get(tn, {}).has("class"):
		pic = emblem_of(tn)                     # the class's emblem on its entry (23 Oct)
	if pic != null and zoom >= (FILLER_PIC_ZOOM if nd.get("filler", false) else PIC_ZOOM):
		var g: float = (r - 2.0 * maxf(0.7, zoom)) * (1.42 if diamond else 1.7)
		g = minf(g, r * 1.7)
		var shade: Color = Color(1.25, 1.25, 1.25) if taken else (Color(1.1, 1.1, 1.1) if reach else Color(0.85, 0.85, 0.85))     # brighter all round (23 Oct, Matt: "way too dark"): the paintings are dark, so taken lifts past white; untaken 0.5 → 0.85
		_sprite(atlased(pic), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), shade)
	elif zoom >= 0.5 and (nd.get("notable", false) or diamond) and glyph_of(nd) != "":
		var g: float = r * 1.1
		_sprite(atlased(NodeGlyphs.texture(glyph_of(nd))), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	var stack: Array = stack_of(id, nd)
	if not stack.is_empty() and zoom >= 0.6:
		var stack_v: String = "%d/%d" % [int(stack[0]), int(stack[1])]
		var sw: float = _font.get_string_size(stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var named: bool = (nd.get("notable", false) or diamond) and (zoom >= LABEL_ZOOM or id == hover or id == selected)
		_text(_font, p + Vector2(-sw / 2.0, r + 13.0 + (14.0 if named else 0.0)), stack_v, 11, Pal.TEXT if taken else Pal.TEXT_3)
	# the name under a notable, the keystone's level by it, from the label zoom
	if (zoom >= LABEL_ZOOM or id == hover or id == selected) and (nd.get("notable", false) or diamond):
		var fs: int = 12
		var words: String = str(nd["name"])
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_text(_font, p + Vector2(-tw / 2.0, r + 14.0), words, fs, Pal.TEXT if taken or reach else Pal.TEXT_3)
	if diamond and not taken and not theirs and zoom >= 0.6:
		var tag: Array = level_tag(nd)
		if not tag.is_empty():
			_text(_font, p + Vector2(r + 6.0, -r + 4.0), str(tag[0]), 11, Pal.GOOD if tag[1] else Pal.TEXT_3)


# ------------------------------------------------------------------ input

func node_at(screen_p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		var r: float = maxf(12.0, radius_of(node_of(id)) * zoom * (1.15 if id.get_slice("/", 0) == Data.COMMON_TREE else 1.0)) + 4.0     # the Pitch's square corners reach past r (the review)
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
