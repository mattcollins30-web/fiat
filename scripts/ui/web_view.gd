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
const YARD_TONE := Color("8fb3d9")
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
const R_ENTRY := 20.0              # a class's entry node, with the class's emblem on it (23 Oct, Matt: "so it's clear where each class's journey starts")
const R_RING := 1480.0             # the paragon ring (slice 4), round the outside (1300 to 1480, 23 Oct: outside the wheels)
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
	_axis[ring["name"]] = {"at": Vector2(0, -R_RING), "dir": Vector2.RIGHT, "tone": Pal.ACCENT, "label_at": Vector2(R_RING + 30.0, 0.0), "align": 1}     # at the right, where no class sits (23 Oct: the top's is the Drifter's)
	_find_bounds()


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
	return slug_of(str(nd.get("name", "")))


static func slug_of(words: String) -> String:
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
	return out


static func picture(slug: String) -> Texture2D:
	if slug == "":
		return null
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


## The canvas's backdrop (23 Oct, the manifest): art/web/backdrop_<slug>.png under everything, covering the view.
## Training's is "training"; the Map's and the Pitch's name their own.
func backdrop_slug() -> String:
	return "training"


## Whether a region is the class on show's (its wheel lit).
func _lit_wheel(tn: String) -> bool:
	return str(_trees.get(tn, {}).get("class", "")) != "" and str(_trees[tn]["class"]) == str(sim.cls)


## A region's emblem beside its label (23 Oct, the manifest): art/web/region_<slug>.png, drawn EMBLEM tall.
const EMBLEM := 26.0
func emblem_of(tn: String) -> Texture2D:
	return art_at("res://art/web/region_%s.png" % slug_of(tn))


func radius_of(nd: Dictionary) -> float:
	if nd.get("notable", false) and not nd.get("keystone", false) and not nd.get("capstone", false) and picture(picture_slug(nd)) != null:
		return R_NOTABLE_PIC
	if nd.get("entry", false) and entry_emblem(nd) != null:
		return R_ENTRY
	return _radius_plain(nd)


## A class's entry node carries the class's emblem (23 Oct): the first lane's region emblem, moved off the rim label.
func entry_emblem(nd: Dictionary) -> Texture2D:
	var tn: String = str(nd.get("region", ""))
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Pal.BG)
	var bd: Texture2D = art_at("res://art/web/backdrop_%s.png" % backdrop_slug())
	if bd != null:
		# the backdrop covers the canvas whole, its proportions kept (the painting's 744 wide at the API's most)
		var k: float = maxf(size.x / bd.get_width(), size.y / bd.get_height())
		var bs: Vector2 = bd.get_size() * k
		draw_texture_rect(bd, Rect2((size - bs) / 2.0, bs), false, Color(1, 1, 1, 0.9))
	if sim == null:
		return
	var view := Rect2(Vector2.ZERO, size).grow(60.0)
	draw_under(view)
	# the links first, under the nodes: lit between two taken, half-lit to a reachable one, dim otherwise
	var links: Dictionary = links_all()
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
			var lit: bool = _lit_wheel(str(a).get_slice("/", 0))     # inside the class's lit wheel the dim links read brighter and thicker (23 Oct)
			var col: Color = LINK_LIT_DIM if lit else LINK_DIM
			if sa.get("taken", false) and sb.get("taken", false):
				col = tone_of(str(a).get_slice("/", 0))
			elif (sa.get("taken", false) and sb.get("reach", false)) or (sb.get("taken", false) and sa.get("reach", false)):
				col = Pal.TEXT
			draw_line(pa, pb, col, LINK_W * (1.4 if lit else 1.0) * maxf(0.6, zoom), true)
	draw_between(view)
	# the nodes
	for id in layout:
		var p: Vector2 = to_screen(layout[id])
		if not view.has_point(p):
			continue
		_draw_node(id, p)
	# the regions' names
	for tn in _axis:
		if _axis[tn].get("hide_label", false):
			continue
		var p: Vector2 = to_screen(_axis[tn]["label_at"])
		if not view.has_point(p):
			continue
		var words: String = region_words(tn)
		var fs: int = 15 if zoom >= 0.6 else 13
		var w: float = _font_bold.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var align: int = int(_axis[tn].get("align", 0))     # -1: the words end at the point; 1: start there; 0: centred
		var em: Texture2D = emblem_of(tn) if str(_axis[tn].get("class", "")) == "" else null     # a class's emblem is on its entry node (23 Oct)
		var es: float = EMBLEM * clampf(zoom, 0.7, 1.2) if em != null else 0.0
		var full: float = w + (es + 6.0 if em != null else 0.0)     # the emblem leads the words
		var x0: float = p.x - full if align < 0 else (p.x if align > 0 else p.x - full / 2.0)
		var tone: Color = Pal.ACCENT if str(_axis[tn].get("class", "")) != "" and str(_axis[tn]["class"]) == str(sim.cls) else tone_of(tn)
		if em != null:
			draw_texture_rect(em, Rect2(x0, p.y + 5.0 - fs * 0.78 - (es - fs) / 2.0, es, es), false)
			x0 += es + 6.0
		draw_string(_font_bold, Vector2(x0, p.y + 5.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tone)


## Under everything (23 Oct, the canvas pass): a warm disc under the wheel of the class on show, so you know where
## you're starting from; each element's region in a hull of its colour - a faint wash, a line - so it reads at a glance.
func draw_under(view: Rect2) -> void:
	for tn in _axis:
		var ax: Dictionary = _axis[tn]
		if ax.has("wheel") and not ax.get("hide_label", false) and str(ax.get("class", "")) == str(sim.cls):
			var c: Vector2 = to_screen(ax["wheel"])
			var r: float = ((Data.WHEEL_R + Data.WHEEL_TRACK / 2.0) * ROW + WHEEL_GLOW) * zoom
			if view.grow(r).has_point(c):
				draw_circle(c, r, Color(Pal.BG, 0.55))        # darker than the links, not warmer (23 Oct: the warm wash lost the lines)
				draw_circle(c, r, Color(Pal.ACCENT, 0.04))
				draw_arc(c, r, 0.0, TAU, 96, Color(Pal.ACCENT, 0.3), 1.5, true)
	for tn in _trees:
		var t: Dictionary = _trees[tn]
		if not t.has("element"):
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
		draw_colored_polygon(pts, Color(tone, 0.05))
		pts.append(pts[0])
		draw_polyline(pts, Color(tone, 0.6), 1.4 * maxf(0.7, zoom), true)


func _joint_half(tree_name: String, key: String) -> String:
	var t: Dictionary = _trees.get(tree_name, {})
	for i in range(t.get("nodes", []).size()):
		if str(t["nodes"][i].get("joint", "")) == key:
			return "%s/%d" % [tree_name, i]
	return ""


func _draw_node(id: String, p: Vector2) -> void:
	var nd: Dictionary = node_of(id)
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
	# the picture across the disc from PIC_ZOOM (23 Oct, the art), dimmed until it's reached; else the glyph from half zoom
	var pic: Texture2D = picture(picture_slug(nd)) if (nd.get("notable", false) or diamond) else null
	if pic == null and nd.get("entry", false) and _trees.get(tn, {}).has("class"):
		pic = emblem_of(tn)                     # the class's emblem on its entry (23 Oct)
	if pic != null and zoom >= PIC_ZOOM:
		var g: float = (r - 2.0 * maxf(0.7, zoom)) * (1.42 if diamond else 1.7)
		g = minf(g, r * 1.7)
		var shade: Color = Color.WHITE if taken else (Color(0.85, 0.85, 0.85) if reach else Color(0.5, 0.5, 0.5, 0.8))
		draw_texture_rect(pic, Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), false, shade)
	elif zoom >= 0.5 and (nd.get("notable", false) or diamond) and glyph_of(nd) != "":
		var tex: Texture2D = NodeGlyphs.texture(glyph_of(nd))
		if tex != null:
			var g: float = r * 1.1
			draw_texture_rect(tex, Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), false, tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	var stack: Array = stack_of(id, nd)
	if not stack.is_empty() and zoom >= 0.6:
		var stack_v: String = "%d/%d" % [int(stack[0]), int(stack[1])]
		var sw: float = _font.get_string_size(stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var named: bool = (nd.get("notable", false) or diamond) and (zoom >= LABEL_ZOOM or id == hover or id == selected)
		draw_string(_font, p + Vector2(-sw / 2.0, r + 13.0 + (14.0 if named else 0.0)), stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.TEXT if taken else Pal.TEXT_3)
	# the name under a notable, the keystone's level by it, from the label zoom
	if (zoom >= LABEL_ZOOM or id == hover or id == selected) and (nd.get("notable", false) or diamond):
		var fs: int = 12
		var words: String = str(nd["name"])
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(_font, p + Vector2(-tw / 2.0, r + 14.0), words, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Pal.TEXT if taken or reach else Pal.TEXT_3)
	if diamond and not taken and not theirs and zoom >= 0.6:
		var tag: Array = level_tag(nd)
		if not tag.is_empty():
			draw_string(_font, p + Vector2(r + 6.0, -r + 4.0), str(tag[0]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Pal.GOOD if tag[1] else Pal.TEXT_3)


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
