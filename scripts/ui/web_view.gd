extends Control
## The skill web, version two (4 Nov, docs/design/skill_web.md; the canvas's round six): one web of 1,549 nodes every
## runner lights its own path on - the centre's clusters, six element columns, a class between each two (its attack
## track left, its other track right, staying up, finds and skills up the middle, its own corner at the top) - drawn
## in the Training room's body from the sim's layout (Data.web_ids / web_at / web_links / web_theme), the paragon ring
## round the outside. Panned with the right button, zoomed with the wheel, a node picked with the left.
##
## A node's three states: owned (lit in its colour, a glow), can take (Sim.web_frontier: an amber ring), not yet
## (dark). A class's nodes take their track's colour (TRACK_TONES: the attack track red, the other teal, staying up
## blue, finds gold, skills purple), an element's its own, the centre's amber. Lesser nodes are dots at the whole web.
## The fourteen names (six classes, six elements, the centre, the ring) are placed clear of every node (_place_names).
##
## Speed (BUILD49 V): the links are kept in web space, gathered by colour, and drawn under one transform (no per-link
## work a frame); the nodes are read from packed arrays, culled to the view and drawn from the one atlas.
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
const Words := preload("res://scripts/sim/words.gd")
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
const TRACK_LINK_DIM := 0.4             # a class track's link not lit: its colour at this (BUILD49 V)
const RING_DIM := 0.35                  # a dark node's ring: the card line with this of its region's colour
const GLOW := 0.2                       # an owned node's glow, its colour at this
const GLOW_R := 1.9                     # and its size against the node's
## The centre in amber (3 Nov, Matt's canvas): the camp's sand, apart from The cold's blue and the frontier's ring.
const PITCH_TONE := Color("d1a65f")
## The class's tracks (round six's canvas, BUILD49 V): the node's track (Data.web_theme) gives its colour.
const TRACK_TONES := {"dmg": Color("e0705a"), "ctl": Color("5fb3a8"), "def": Color("8fb4e0"), "loot": Color("d9b25a"), "skill": Color("b49ad6"), "start": Color("e3a33b")}
const DOT_MIN := 1.6               # a lesser node's dot at the whole web, px at least
const BIG_MIN := 2.8               # a big node's disc at the whole web, px at least
const DARK_DOT := 0.7              # a dark lesser node's dot: its colour at this over the canvas
const RING_GAP := 45.0             # the paragon ring past the web's furthest node (web units; skill_web.md: the ring at 1,120)
const FRONTIER := Pal.ACCENT
const PIC_ZOOM := 0.5              # a big node's picture from here; its glyph before
## The small nodes' art (3 Nov, 0.12.1, Matt: "whats with the lack of art?"): from SMALL_ART_ZOOM a small node grows to
## as much of R_SMALL_ART as its neighbours leave it (_small_cap) and carries its picture (art/nodes/<slug of its name>.png
## - every "Hardy" the one picture) or else its effect's glyph; further out it stays a dot (0.11.0's FILLER_PIC_ZOOM).
const SMALL_ART_ZOOM := 1.1
const R_SMALL_ART := 8.0
const SMALL_GAP := 4.5            # the room a grown small leaves its neighbours (the smoke's overlap check wants 4)
## The regions' emblems (0.12.1, as 0.11.0 drew them): an element's and the ring's beside its name; each class tree's by
## the middle of its nodes in its class's corner; the centre's by the middle - each where it covers no node, no name and
## no other emblem, EMBLEM_PX at any zoom.
const EMBLEM_PX := 22.0
## The runner's class's portrait (0.12.1, 0.11.0's wheel disc): faint under its start's flower, faded to its rim.
const PORTRAIT_R := 44.0
const PORTRAIT_SHADE := Color(1, 1, 1, 0.42)
## A picture not there is looked for again after this (an art drop shows in a running game; Training's open re-looks).
const ART_RECHECK_MS := 3000
const R_RING := Data.RING_R        # (the sim's ring radius; the canvas draws it at ring_r(), past the web's furthest node)
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
var _track := {}                   # id -> its track (Data.web_theme): dmg / ctl / def / loot / skill / start, "" for none
var _ring_r := R_RING              # the ring's radius on the canvas (ring_r)
var _ids: Array = []               # every id in layout order, for the packed reads below
var _pos := PackedVector2Array()   # their places (web units)
var _kidx := PackedByteArray()     # their kinds: KINDS' index
var _st := PackedByteArray()       # their states as last restated: 0 dark, 1 can take, 2 owned
var _named: Array = []             # the ids with a name to show close in (the big nodes')
var _ix := {}                      # id -> its index in the packed reads
var _tones := PackedColorArray()   # their colours
var _dark := PackedColorArray()    # a dark lesser node's dot (DARK_DOT over the canvas)
const KINDS := ["small", "notable", "skill", "start", "keystone", "capstone", "ring"]
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
var _small_cap := {}               # a small node's slot -> the radius its neighbours leave it (web units), up to R_SMALL_ART
var block_sizes := {}              # the last frame's names: key -> [the words' px, the emblems' px] (the smoke's)
var emblem_rects := {}             # the last frame's emblems on screen, "<name's key>#<n>" -> Rect2 (the smoke's)
var portrait_rect := Rect2()       # the last frame's portrait, on screen (the smoke's)
var keep_clear: Array = []         # the canvas's rects the screen lays over it (Training's tabs and key): no name there at the whole web


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


## Every node at the sim's place (web units, the centre at 0,0, 12 o'clock up), its region, kind, track and colour; the
## ring's thirty round the outside at their angles (ring_r); the fourteen names placed clear of the nodes.
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
	_track = {}
	var cls_names := {}
	for cd in Data.CLASSES:
		cls_names[str(cd["name"])] = true
	var el_names := {}
	for t in Data.ELEMENT_TREES:
		el_names[str(t["name"])] = true
	var far := 0.0
	for id in Data.web_ids():
		var sid := str(id)
		layout[sid] = Data.web_at(sid)
		_region[sid] = norm_region(Data.web_region(sid), cls_names, el_names)
		_kind[sid] = Data.web_kind(sid)
		_track[sid] = Data.web_theme(sid)
		far = maxf(far, Vector2(layout[sid]).length())
	for sid in layout:
		_tone[sid] = region_tone(sid)
		_links[sid] = web_links_of(str(sid)).duplicate()
	# the ring (slice 4): its nodes round the outside at their angles, joined round, RING_GAP past the furthest node
	_ring_r = maxf(R_RING, far + RING_GAP) if not layout.is_empty() else R_RING
	var ring: Dictionary = Data.RING
	for i in range(ring["nodes"].size()):
		var rid: String = "%s/%d" % [ring["name"], i]
		layout[rid] = Data.web_at(rid).normalized() * _ring_r      # at its angle, on the canvas's ring
		_region[rid] = "ring"
		_kind[rid] = "ring"
		_tone[rid] = Pal.ACCENT
		var out: Array = []
		for j in ring["nodes"][i].get("links", []):
			out.append("%s/%d" % [ring["name"], int(j)])
		_links[rid] = out
	_pack_ids()
	# the names (round six: "the class names clear of the nodes"): a class's out along its line past its tracks, an
	# element's on its column, the centre's under the hub, the ring's outside it - each placed by _place_names
	for cd in Data.CLASSES:
		var key: String = "class:%s" % cd["name"]
		var st: String = Data.web_start(str(cd["name"]))
		if layout.has(st):
			_axis[key] = {"anchor": Vector2.from_angle(Vector2(layout[st]).angle()) * CLASS_NAME_R, "span": NAME_SPAN, "words": str(cd["name"]), "tone": Pal.TEXT}
			_trees[key] = {"name": key, "class": str(cd["name"])}     # what each name is (the tests' reads, as the trees were)
	for t in Data.ELEMENT_TREES:
		var tn: String = str(t["name"])
		var key: String = "el:" + tn
		var at := Vector2.ZERO
		var n := 0
		for id in layout:
			if _region[id] == key:
				at += layout[id]
				n += 1
		if n == 0:
			continue
		_axis[key] = {"anchor": Vector2.from_angle(at.angle()) * ELEMENT_NAME_R, "span": NAME_SPAN, "words": plain_name(tn), "tone": element_tone(tn)}
		_trees[key] = {"name": key, "element": t.get("element", "")}
	_trees["ring"] = {"name": "ring", "ring": true}
	_axis["ring"] = {"anchor": Vector2.from_angle(deg_to_rad(RING_LABEL_DEG)) * (_ring_r + 60.0), "span": 30.0, "words": plain_name(Data.RING_TREE), "tone": Pal.ACCENT}
	# the centre's name (0.12.2, Matt: the icons "centered above their names"): the room's word on the rail, the rename parked
	_axis["centre"] = {"anchor": Vector2.from_angle(deg_to_rad(CENTRE_NAME_DEG)) * CENTRE_NAME_R, "span": 0.0, "words": Words.WEB_SCREEN["centre_name"], "tone": PITCH_TONE}
	_trees["centre"] = {"name": "centre"}
	# each name's emblems over it: an element's, a class's two trees' (its left lane's and its right's), the centre's, the ring's
	for key in _axis:
		var ems: Array = []
		if str(key).begins_with("el:"):
			ems = [emblem_of(str(key).substr(3))]
		elif str(key).begins_with("class:"):
			for t in Data.TREES:
				if "class:" + str(t.get("class", "")) == str(key):
					ems.append(emblem_of(str(t["name"])))
		elif key == "centre":
			ems = [emblem_of(Data.COMMON_TREE)]
		elif key == "ring":
			ems = [emblem_of(Data.RING_TREE)]
		_axis[key]["emblems_all"] = ems.filter(func(e): return e != null)
		_axis[key]["emblems"] = _axis[key]["emblems_all"]
		_axis[key]["k"] = 1.0
		_axis[key]["gap"] = 1.0
	_small_caps()
	_find_bounds()
	_labels_by_entry()


## The layout's region as the canvas names it: "class:<Class>", "el:<element tree>", "centre", "ring" (the sim's
## version one said so already; version two's layout says "Poacher", "The cold").
static func norm_region(rg: String, cls_names: Dictionary, el_names: Dictionary) -> String:
	if rg.begins_with("class:") or rg.begins_with("el:") or rg in ["centre", "ring", "join", ""]:
		return rg
	if cls_names.has(rg):
		return "class:" + rg
	if el_names.has(rg):
		return "el:" + rg
	return rg


## The packed reads (BUILD49 V: the frame reads arrays, not a dictionary a node).
func _pack_ids() -> void:
	_ids = layout.keys()
	_pos = PackedVector2Array()
	_kidx = PackedByteArray()
	_named = []
	_ix = {}
	_tones = PackedColorArray()
	_dark = PackedColorArray()
	for id in _ids:
		_ix[id] = _pos.size()
		var tone: Color = _tone.get(id, Pal.TEXT)
		_tones.append(tone)
		_dark.append(Pal.BG.lerp(tone, DARK_DOT))
		_pos.append(layout[id])
		var k: int = KINDS.find(str(_kind.get(id, "small")))
		_kidx.append(maxi(0, k))
		if k > 0 and k < 6:
			_named.append(id)
	_st = PackedByteArray()
	_st.resize(_ids.size())


## The ring's radius on the canvas: the sim's, or RING_GAP past the web's furthest node (version two's 1,120).
func ring_r() -> float:
	return _ring_r


## A node's colour: a class's by its track (TRACK_TONES), the centre amber, an element (and its joins) its own, the
## ring the accent; a class node with no track white.
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
	return TRACK_TONES.get(str(_track.get(id, "")), Pal.TEXT)


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


## What a small node carries at this zoom (0.12.1): "picture" (art/nodes/<slug>.png, found by name at draw time),
## "glyph" (its effect's, node_glyphs.gd), or "" - a dot, further out than SMALL_ART_ZOOM (or a big node: its own pass).
func small_art_of(id: String) -> String:
	if big_kind(str(_kind.get(id, "small"))) or zoom < SMALL_ART_ZOOM:
		return ""
	var nd: Dictionary = node_of(id)
	if picture(picture_slug(nd)) != null:
		return "picture"
	return "glyph" if glyph_of(nd) != "" else ""


## Whether this canvas draws the skill web (Training's), not one of the older canvases built on it.
func nodes_are_web() -> bool:
	return not layout.is_empty() and _small_cap.size() > 0


## A region's name over it: the name alone (28 Oct, Matt: "it should just say 'Rat Man' ... same for the classes, just
## the class names") - no "The".
static func plain_name(tn: String) -> String:
	var n: String = tn.trim_prefix("The ").trim_prefix("the ")
	return n.left(1).to_upper() + n.substr(1) if n != "" else tn


## The fourteen names placed for the whole web's zoom - the furthest out the canvas goes - so closer in each only
## shrinks about its point (BUILD49 V, round six: "the class names clear of the nodes"). Each from its preferred point
## (a class's out along its line, an element's on its column, the centre's under the hub, the ring's outside it), the
## places tried nearest first on a NAME_STEP grid out to NAME_REACH, within NAME_SPAN degrees of its line: the first
## where the block, words LABEL_SLACK wide, keeps BLOCK_CLEAR off every node's disc (a lesser one as grown close in) and
## every name placed before it, inside the ring (the ring's: outside it) and on the canvas. The largest size that finds
## a place, its emblems over it where they fit (NAME_KS), without them where they don't. Worked once a layout (static).
const LABEL_NEAR := 560.0           # a name within this of its preferred point is by it (the smoke's reach: NAME_REACH)
const LABEL_STEP := 10.0
const NAME_STEP := 10.0
const NAME_REACH := 560.0
const NAME_SPAN := 12.0             # degrees either side of its line (a neighbour's line is 30 off)
const CLASS_NAME_R := 900.0         # a class's preferred point: past its tracks, under its corner
const ELEMENT_NAME_R := 520.0       # an element's: on its column (the canvas's P(520))
const CENTRE_NAME_R := 60.0         # the centre's: under the hub
const CENTRE_NAME_DEG := 90.0
const NAME_KS := [1.0, 0.93, 0.86, 0.79, 0.72, 0.65, 0.58]     # 14 px down to NAME_MIN (past 0.72 the words stay at 10, the emblems shrink)
## The places found (BUILD49 V, the search below run offline on the version-two layout at Training's 1040 x 684 canvas:
## tests/web_names_tool.gd, never at runtime - it takes seconds): key -> [x, y, k, its emblems: 0 none, 1 over the words, 2 beside
## them, at their left (where over doesn't fit)]. The smoke holds each clear of
## every node (stored_unfit) at that canvas and a 4 px shorter one; a canvas of another size, or a key not here, searches.
const NAME_AT := {
	"class:Poacher": [20.0, -1040.0, 0.72, 2], "class:Paramedic": [1109.4, -680.0, 1.00, 1], "class:Scrapper": [1099.4, 670.0, 1.00, 1],
	"class:Drifter": [-100.0, 1010.0, 0.86, 1], "class:Doorman": [-1179.4, 510.0, 1.00, 1], "class:Recruit": [-919.4, -400.0, 0.79, 1],
	"el:The cold": [290.0, -890.3, 0.93, 1], "el:Live": [900.0, -190.0, 0.86, 1], "el:Petrol": [280.0, 850.3, 0.72, 2],
	"el:Blades": [-290.0, 880.3, 0.72, 1], "el:Knuckles": [-940.0, -190.0, 0.72, 2], "el:The Rat Man": [-300.0, -850.3, 0.58, 2],
	"ring": [-809.6, -936.9, 1.00, 1], "centre": [240.0, 220.0, 0.72, 0],
}
const NAME_CANVAS := Vector2(1040, 684)
static var _name_grid: Array = []
static var _names_cache := {}       # "sig" -> {key: [label_at, k, gap, with emblems]}


## The offsets a name tries, nearest first.
static func label_grid(_wide := false) -> Array:
	if _name_grid.is_empty():
		var n: int = int(NAME_REACH / NAME_STEP)
		for gx in range(-n, n + 1):
			for gy in range(-n, n + 1):
				var d := Vector2(gx, gy) * NAME_STEP
				if d.length() <= NAME_REACH:
					_name_grid.append(d)
		_name_grid.sort_custom(func(a, b): return a.length() < b.length() or (a.length() == b.length() and (a.y < b.y or (a.y == b.y and a.x < b.x))))
	return _name_grid


## How far a name may go from its point.
func label_near(_key: String) -> float:
	return LABEL_NEAR


func _labels_by_entry() -> void:
	_place_names()


## The names placed (or read back from the last placing of this layout at this size).
func _place_names() -> void:
	var zf: float = fit_zoom()
	var sig := "%d|%.1f|%s|%.2f" % [layout.size(), _ring_r, str(size), _pos_sum()]
	var keep: Dictionary = _names_cache.get(sig, {})
	if keep.is_empty() and size == NAME_CANVAS and _axis.keys().all(func(k): return NAME_AT.has(k)):
		for key in _axis:
			var n: Array = NAME_AT[key]
			keep[key] = [Vector2(float(n[0]), float(n[1])), float(n[2]), 1.0, int(n[3])]
		_names_cache[sig] = keep
	if keep.is_empty():
		_index_nodes(_name_r)
		var placed: Array = []
		var order: Array = _axis.keys()
		order.sort_custom(func(a, b): return _name_rank(str(a)) < _name_rank(str(b)))
		for key in order:
			keep[key] = _place_one(str(key), zf, placed)
			placed.append(label_box_at(str(key), keep[key][0], zf))
			if str(key).begins_with("class:"):
				placed.append(_portrait_box(str(key), keep[key][0], zf))     # the runner's face goes under its class's name
		_near = {}
		_names_cache[sig] = keep
	for key in _axis:
		var got: Array = keep.get(key, [])
		if got.is_empty():
			continue
		var ax: Dictionary = _axis[key]
		ax["label_at"] = got[0]
		ax["k"] = got[1]
		ax["gap"] = got[2]
		ax["emblems"] = ax["emblems_all"] if int(got[3]) > 0 else []
		ax["inline"] = int(got[3]) == 2
		ax["label_box"] = label_box_at(str(key), got[0], zf)


static func _name_rank(key: String) -> int:
	return 0 if key == "ring" else (1 if key == "centre" else (3 if key.begins_with("class:") else 2))     # the classes last: their faces keep off the rest


func _pos_sum() -> float:
	var t := 0.0
	for p in _pos:
		t += p.x * 0.37 + p.y
	return t


## A node's room for the names: a lesser one as grown close in (the most it takes), a big one its kind's.
func _name_r(id: String) -> float:
	if _kind.get(id, "") == "small":
		return float(_small_cap.get(Data.web_slot(str(id)), R_SMALL))
	return radius_by_kind(str(_kind.get(id, "small")))


## One name's place: [label_at, k, gap, emblems shown]; the preferred point at the smallest size where none clears.
func _place_one(key: String, zf: float, placed: Array) -> Array:
	var ax: Dictionary = _axis[key]
	var pref: Vector2 = ax["anchor"]
	var span: float = float(ax.get("span", 0.0))
	var seen := Rect2(whole_cam(zf) - size / zf / 2.0, size / zf)     # the canvas at the whole web, web units
	var zf_s: float = clampf(minf(size.x / _bounds.size.x, (size.y - 4.0 - FRAME_TOP) / _bounds.size.y), ZOOM_MIN, ZOOM_MAX)     # and one 4 px shorter (Windows' margin)
	for pass_ in [[1, false], [2, false], [1, true], [0, false]]:     # over, beside, over past the ring, none
		var mode: int = pass_[0]
		var outside: bool = pass_[1] or key == "ring"
		var with_em: bool = mode > 0
		if with_em and Array(ax["emblems_all"]).is_empty():
			continue
		ax["emblems"] = ax["emblems_all"] if with_em else []
		ax["inline"] = mode == 2
		for k in (NAME_KS if with_em else NAME_KS.slice(0, 5)):
			ax["k"] = k
			ax["gap"] = 1.0
			var d: Dictionary = block_dims(key, zf, zf, LABEL_SLACK)
			var wh := Vector2(d["w"], d["h"]) / zf
			for off in label_grid():
				var at: Vector2 = pref + off
				if span > 0.0 and absf(angle_difference(at.angle(), pref.angle())) > deg_to_rad(span):
					continue
				var rc := Rect2(at - wh / 2.0, wh)
				if not seen.encloses(rc):
					continue
				if outside:
					if _rect_near(rc) < _ring_r + R_RING_NODE + BLOCK_CLEAR / zf:
						continue
				elif not _inside_ring(rc):
					continue
				if placed.any(func(b): return Rect2(b).intersects(rc)):
					continue
				if key.begins_with("class:") and placed.any(func(b): return Rect2(b).intersects(_portrait_box(key, at, zf))):
					continue
				var rc_s: Rect2 = _block_at(key, at, zf_s)
				if _over_kept(rc, zf) or _over_kept(rc_s, zf_s, size - Vector2(0, 4)) or not (_inside_ring(rc_s) or _rect_near(rc_s) >= _ring_r + R_RING_NODE):
					continue
				if _block_depth(rc, zf) <= 0.0 and _block_depth(rc_s, zf_s) <= 0.0:
					return [at, k, 1.0, mode]
	ax["inline"] = false
	return [pref, NAME_KS[-1], 1.0, 0]


## Whether a web-unit rect, at the whole web of zoom `zf`, lies under one of the screen's own rects (keep_clear).
func _over_kept(rc: Rect2, zf: float, sz := Vector2.ZERO) -> bool:
	var c: Vector2 = size if sz == Vector2.ZERO else sz
	var on := Rect2((rc.position - whole_cam(zf)) * zf + c / 2.0, rc.size * zf)
	var dy: float = c.y - size.y                 # the key sits at the canvas's foot: it moves with a shorter one
	for k in keep_clear:
		var kr := Rect2(k)
		if kr.position.y > FRAME_TOP:
			kr.position.y += dy
		if kr.intersects(on):
			return true
	return false


## The square round a class's portrait (draw_under: on its name, its block's half width and 10 px) in web units.
func _portrait_box(key: String, at: Vector2, zf: float) -> Rect2:
	var d: Dictionary = block_dims(key, zf, zf, LABEL_SLACK)
	var r: float = maxf(PORTRAIT_R * zf, d["w"] / 2.0 + 10.0) / zf
	return Rect2(at - Vector2(r, r), Vector2(r, r) * 2.0)


## A name's block in web units at `at`, drawn as at the whole web of zoom `zf`, its words LABEL_SLACK wide.
func _block_at(key: String, at: Vector2, zf: float) -> Rect2:
	var d: Dictionary = block_dims(key, zf, zf, LABEL_SLACK)
	var wh := Vector2(d["w"], d["h"]) / zf
	return Rect2(at - wh / 2.0, wh)


## A rect's nearest point to the centre, its distance.
static func _rect_near(rc: Rect2) -> float:
	return Vector2(clampf(0.0, rc.position.x, rc.end.x), clampf(0.0, rc.position.y, rc.end.y)).length()


## A name and its emblems as one block (0.12.2, Matt: the icons "centered above their names"):
## the emblems side by side over the words, centred on the words' middle, a lift above them, on a dark plate so a link
## under it doesn't cut the words. Each block has its size in web units (k, from _place_names: the largest that finds a
## place clear of every node) and is drawn at that size times the zoom, the words clamped to NAME_MIN..NAME_SIZE px and
## the emblems to EMBLEM_MIN..EMBLEM_MAX.
const NAME_MIN := 10.0
const EMBLEM_MIN := 12.0
const EMBLEM_MAX := 24.0
const EMBLEM_LIFT := 2.0           # between an emblem's foot and its name's top (px, at full size)
const EMBLEM_SEP := 4.0            # between a class's two (px, at full size)
const PLATE_PAD := 2.0             # the plate past the words and emblems (px)
const BLOCK_CLEAR := 1.0           # a block's room from a node's disc at the whole web (px), its words LABEL_SLACK wide


## A block's parts on screen at zoom `z`: the words' and emblems' sizes, the lift, the spacing, the words' width, the
## block's width and height (plate included).
func block_dims(key: String, z: float, zf := -1.0, slack := 1.0) -> Dictionary:
	var ax: Dictionary = _axis[key]
	var k: float = float(ax.get("k", 1.0))
	var g: float = float(ax.get("gap", 1.0))
	var f: float = k * z / maxf(0.01, zoom_min if zf < 0.0 else zf)
	var ts: float = clampf(NAME_SIZE * f, NAME_MIN, NAME_SIZE)
	var es: float = clampf(EMBLEM_PX * f, EMBLEM_MIN, EMBLEM_MAX)
	var lift: float = g * minf(EMBLEM_LIFT * f, EMBLEM_LIFT)
	var sep: float = g * minf(EMBLEM_SEP * f, EMBLEM_SEP)
	var ww: float = _font_bold.get_string_size(str(ax["words"]), HORIZONTAL_ALIGNMENT_LEFT, -1, int(round(ts))).x * slack
	var n: int = Array(ax.get("emblems", [])).size()
	var row: float = n * es + maxf(0.0, n - 1.0) * sep
	if n > 0 and ax.get("inline", false):     # the emblems beside the words, at their left (BUILD49 V)
		return {"ts": ts, "es": es, "lift": lift, "sep": sep, "ww": ww, "w": row + INLINE_GAP + ww + 2.0 * PLATE_PAD,
			"h": maxf(ts * 1.1, es) + 2.0 * PLATE_PAD, "row": row}
	return {"ts": ts, "es": es, "lift": lift, "sep": sep, "ww": ww, "w": maxf(ww, row) + 2.0 * PLATE_PAD,
		"h": ts * 1.1 + (es + lift if n > 0 else 0.0) + 2.0 * PLATE_PAD}
const INLINE_GAP := 5.0            # between the emblems beside a name and its words (px)


## A name's whole block on screen as drawn (its plate: the emblems and the words).
func block_rect(key: String) -> Rect2:
	var ax: Dictionary = _axis.get(key, {})
	if not ax.has("label_at"):
		return Rect2()
	var p: Vector2 = to_screen(ax["label_at"])
	var d: Dictionary = block_dims(key, zoom)
	return Rect2(p.x - d["w"] / 2.0, p.y - d["h"] / 2.0, d["w"], d["h"])


## A name's emblems on screen as drawn, left to right.
func emblem_rects_of(key: String) -> Array:
	var ax: Dictionary = _axis.get(key, {})
	var ems: Array = ax.get("emblems", [])
	if ems.is_empty() or not ax.has("label_at"):
		return []
	var words: Rect2 = label_rect(key)
	var d: Dictionary = block_dims(key, zoom)
	var e: float = d["es"]
	var row: float = ems.size() * e + (ems.size() - 1) * float(d["sep"])
	var out: Array = []
	if d.has("row"):
		var br: Rect2 = block_rect(key)
		for i in range(ems.size()):
			out.append(Rect2(br.position.x + PLATE_PAD + i * (e + float(d["sep"])), br.get_center().y - e / 2.0, e, e))
		return out
	var x0: float = words.get_center().x - row / 2.0
	for i in range(ems.size()):
		out.append(Rect2(x0 + i * (e + float(d["sep"])), words.position.y - float(d["lift"]) - e, e, e))
	return out


## Each name whose placed block, drawn as at the whole web of zoom `zf` with its words LABEL_SLACK wide, comes within
## BLOCK_CLEAR of a node's disc or leaves its side of the ring: how far in (px). The smoke's (empty when every name clears).
func stored_unfit(zf: float, canvas_h := -1.0) -> Dictionary:
	var out := {}
	var sz := Vector2(size.x, canvas_h if canvas_h > 0.0 else size.y)
	_index_nodes(_name_r)
	for key in _axis:
		if not _axis[key].has("label_at"):
			out[key] = INF
			continue
		var d: Dictionary = block_dims(str(key), zf, zf, LABEL_SLACK)
		var at: Vector2 = _axis[key]["label_at"]
		var rc := Rect2(at - Vector2(d["w"], d["h"]) / zf / 2.0, Vector2(d["w"], d["h"]) / zf)
		var deep: float = _block_depth(rc, zf)
		var side: bool = _inside_ring(rc) or _rect_near(rc) >= _ring_r + R_RING_NODE     # inside the ring or past it, never on it
		if deep > 0.0 or not side or _over_kept(rc, zf, sz):
			out[key] = maxf(deep, 0.0)
	_near = {}
	return out


func _inside_ring(rc: Rect2) -> bool:
	var lim: float = _ring_r - R_RING_NODE - 4.0
	return rc.end.length() <= lim and rc.position.length() <= lim and Vector2(rc.position.x, rc.end.y).length() <= lim and Vector2(rc.end.x, rc.position.y).length() <= lim


## How far (px at zoom `zf`) the nearest node's disc, plus BLOCK_CLEAR, reaches into a web-unit rect; <= 0 when clear.
## Bucketed: _index_nodes(_name_r) first.
func _block_depth(rc: Rect2, zf: float) -> float:
	var deep := -INF
	for id in _ids_in(rc.grow(_rad_max + (BLOCK_CLEAR + 2.0) / zf)):     # every node that could come within BLOCK_CLEAR px (the b45 check)
		var q: Vector2 = layout[id]
		var r: float = float(_rad[id])
		var d: float = Vector2(clampf(q.x, rc.position.x, rc.end.x), clampf(q.y, rc.position.y, rc.end.y)).distance_to(q)
		deep = maxf(deep, (r - d) * zf + BLOCK_CLEAR)
	return deep


## Each small node's room (web units): up to R_SMALL_ART, SMALL_GAP clear of every neighbour at its own full size (two
## smalls share what's between them). Bucketed (version two's 1,549 nodes).
func _small_caps() -> void:
	_small_cap = {}
	_index_nodes(func(id): return radius_by_kind(str(_kind.get(id, "small"))))
	var reach: float = 2.0 * R_SMALL_ART + SMALL_GAP + R_CAPSTONE
	for a in layout:
		if _kind.get(a, "") != "small":
			continue
		var cap: float = R_SMALL_ART
		var pa: Vector2 = layout[a]
		for b in _ids_in(Rect2(pa, Vector2.ZERO).grow(reach)):
			if b == a:
				continue
			var d: float = pa.distance_to(layout[b])
			if d > reach:
				continue
			if _kind.get(b, "") == "small":
				cap = minf(cap, (d - SMALL_GAP) / 2.0)
			else:
				cap = minf(cap, d - radius_by_kind(str(_kind.get(b, "small"))) - SMALL_GAP)
		_small_cap[Data.web_slot(str(a))] = maxf(R_SMALL, cap)
	_near = {}


## The zoom the names are placed for: the whole web's.
## The whole web sits under the tabs (BUILD49 V: version two's top ran under them): the canvas less FRAME_TOP high.
func fit_zoom() -> float:
	return clampf(minf(size.x / _bounds.size.x, (size.y - FRAME_TOP) / _bounds.size.y), ZOOM_MIN, ZOOM_MAX)


## The whole web's camera at zoom `z`: the web's middle in the canvas under the tabs.
func whole_cam(z: float) -> Vector2:
	return _bounds.get_center() - Vector2(0.0, FRAME_TOP / 2.0) / z


## A name's box in web units at zoom `z`, centred on `at`.
func label_box_at(key: String, at: Vector2, z: float) -> Rect2:
	var d: Dictionary = block_dims(key, z)          # the name and its emblems, as one block (0.12.2)
	var w: float = float(d["w"]) / z
	var h: float = float(d["h"]) / z
	return Rect2(at.x - w / 2.0, at.y - h / 2.0, w, h)


const LABEL_SLACK := 1.06          # the words measured a little wide: Windows' shaping runs a few px wider than the cloud's (25 Oct)


## A region's name on screen as drawn at this zoom (for the smoke and the hover).
func label_rect(key: String) -> Rect2:
	var ax: Dictionary = _axis.get(key, {})
	if not ax.has("label_at"):
		return Rect2()
	var p: Vector2 = to_screen(ax["label_at"])
	var d: Dictionary = block_dims(key, zoom)
	if d.has("row"):                          # beside its emblems: the words at the block's right, centred down it
		return Rect2(p.x + d["w"] / 2.0 - PLATE_PAD - d["ww"], p.y - d["ts"] * 0.55, d["ww"], d["ts"] * 1.1)
	return Rect2(p.x - d["ww"] / 2.0, p.y + d["h"] / 2.0 - PLATE_PAD - d["ts"] * 1.1, d["ww"], d["ts"] * 1.1)     # the words at the block's foot


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
	var r: float = _ring_r + BOUNDS_PAD
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
	zoom = clampf(fit_zoom(), zoom_min, ZOOM_MAX)
	cam = whole_cam(zoom)
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
	_frame(box)
	for _pass in range(2):                 # the regions' names in the frame too, at the zoom it comes to (BUILD49 V)
		var named_box := box
		for k in regions:
			if _axis.has(k) and _axis[k].has("label_at"):
				named_box = named_box.merge(label_box_at(str(k), _axis[k]["label_at"], zoom).grow(4.0 / zoom))
		_frame(named_box)


## A web-unit box filling the canvas under the tabs.
func _frame(box: Rect2) -> void:
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


## A class's corner (3 Nov; version two, BUILD49 V): the class's nodes and its two elements' columns, framed.
func focus_class(cls: String) -> void:
	focus_regions(corner_regions(cls))


## The class's region and the two elements beside it: the two element columns nearest its line (its left one
## anticlockwise of it, its right one clockwise), the left first.
func corner_regions(cls: String) -> Array:
	var key: String = "class:" + cls
	var st: String = Data.web_start(cls)
	if not layout.has(st):
		return [key]
	var a: float = Vector2(layout[st]).angle()
	var sums := {}
	for id in layout:
		var rg: String = str(_region[id])
		if rg.begins_with("el:"):
			sums[rg] = Vector2(sums.get(rg, Vector2.ZERO)) + Vector2(layout[id])
	var left := ""
	var right := ""
	var dl := INF
	var dr := INF
	for rg in sums:
		var d: float = angle_difference(a, Vector2(sums[rg]).angle())     # > 0: clockwise of the class (y down)
		if d > 0.0 and d < dr:
			dr = d
			right = rg
		elif d <= 0.0 and -d < dl:
			dl = -d
			left = rg
	return [key] + ([left] if left != "" else []) + ([right] if right != "" else [])


## The Paragon board (BUILD49 V, the third tab): the ring's arc by the runner's class - its entry and the two either
## side - framed.
const RING_ARC := 2
func focus_ring(cls: String) -> void:
	var st: String = Data.web_start(cls) if cls != "" else ""
	var a: float = Vector2(layout[st]).angle() if layout.has(st) else -PI / 2.0
	var box := Rect2()
	var first := true
	for id in ring_arc(a):
		if first:
			box = Rect2(layout[id], Vector2.ZERO)
			first = false
		else:
			box = box.expand(layout[id])
	if first:
		focus_all()
		return
	_frame(box.grow(R_RING_NODE + 40.0))


## The ring's nodes within RING_ARC steps of an angle (radians), nearest first.
func ring_arc(a: float) -> Array:
	var out: Array = []
	for id in layout:
		if _region[id] == "ring" and absf(angle_difference(a, Vector2(layout[id]).angle())) <= deg_to_rad(Data.RING_STEP * (RING_ARC + 0.5)):
			out.append(id)
	out.sort_custom(func(x, y): return absf(angle_difference(a, Vector2(layout[x]).angle())) < absf(angle_difference(a, Vector2(layout[y]).angle())))
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
	if _ids.size() != layout.size():
		_pack_ids()
	_frontier = {}
	if sim != null and sim.has_method("web_frontier"):
		for id in sim.web_frontier(true):          # joined and gated, points or not: the amber ring says where the next point goes
			_frontier[str(id)] = true
	_frontier_read = true
	for i in range(_ids.size()):
		var st: Dictionary = state_for(_ids[i])
		_state[_ids[i]] = st
		_st[i] = 2 if st.get("taken", false) else (1 if st.get("reach", false) else 0)
	_frontier_read = false
	_link_runs_sig = ""                      # the links regathered by colour on the next frame


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
		solid()
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


static var node_art_dir := "res://art/nodes"     # where a node's picture is looked for (the smoke points it at user:// to drop one in)
static func picture(slug: String) -> Texture2D:
	if slug == "":
		return null
	if slug.begins_with("skill/"):
		return art_at("res://art/skills/%s.png" % slug.substr(6))
	return art_at("%s/%s.png" % [node_art_dir, slug])


## A picture by path, looked for once (23 Oct): the nodes', the regions' emblems, the canvases' backdrops. One not there
## is looked for again after ART_RECHECK_MS (0.12.1: an art drop shows without a restart where the files are loose -
## a run from the project; an exported build has its art packed) and on art_rescan().
static var _missed := {}                 # path -> when it was last looked for and not found (msec)
static func art_at(path: String) -> Texture2D:
	if _pics.has(path) and (_pics[path] != null or Time.get_ticks_msec() - int(_missed.get(path, 0)) < ART_RECHECK_MS):
		return _pics[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		tex = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE)     # null, quietly, where a clone's import cache isn't built yet (the review)
	elif FileAccess.file_exists(path):
		var img := Image.load_from_file(ProjectSettings.globalize_path(path))     # a clone without the import cache (the cloud's renders): the file itself
		if img != null:
			tex = ImageTexture.create_from_image(img)
	_pics[path] = tex
	if tex == null:
		_missed[path] = Time.get_ticks_msec()
	return tex


## Every picture looked for again on its next use, found or not (the smoke's art drop and its taking away).
static func art_rescan() -> void:
	_pics = {}
	_missed = {}
	_portraits = {}


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
static var _shape_fast := {}            # kind -> [the four sizes' textures] (BUILD49 V: no key made a node)
static func shape(kind: String, radius: float) -> Texture2D:
	var si: int = DISC_SIZES.size() - 1
	for j in range(DISC_SIZES.size()):
		if DISC_SIZES[j] >= radius * 2.0:
			si = j
			break
	var fast: Array = _shape_fast.get(kind, [])
	if not fast.is_empty() and fast[si] != null:
		return fast[si]
	var n: int = DISC_SIZES[si]
	var key := "%s:%d" % [kind, n]
	if _atlas_of.has(key):
		if fast.is_empty():
			fast = [null, null, null, null]
			_shape_fast[kind] = fast
		fast[si] = _atlas_of[key]
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


## A white cell of the atlas: the names' plates (BUILD49 V: each was a call of its own).
static func solid() -> Texture2D:
	if _atlas_of.has("solid"):
		return _atlas_of["solid"]
	var img := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var out: Texture2D = _pack(img)
	if out == null:
		atlas_misses += 1
		out = ImageTexture.create_from_image(img)
	_atlas_of["solid"] = out
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
	solid()
	for id in layout:
		var nd: Dictionary = node_of(id)
		atlased(picture(picture_slug(nd)))
		if glyph_of(nd) != "":
			atlased(NodeGlyphs.texture(glyph_of(nd)))
	for key in _axis:
		for em in _axis[key].get("emblems", []):
			atlased(em)
	if sim != null and str(sim.get("cls")) != "":
		atlased(wheel_portrait(str(sim.cls)))
	_atlas_flush()
	_ensure_bends()                        # the curved links worked here too, not on a pan's first frame


## The canvas's backdrop (23 Oct, the manifest): art/web/backdrop_<slug>.png under everything, covering the view.
func backdrop_slug() -> String:
	return "training"


## A region's emblem (23 Oct, the manifest): art/web/region_<slug>.png.
const EMBLEM := 26.0
func emblem_of(tn: String) -> Texture2D:
	return art_at("res://art/web/region_%s.png" % Items.slug(tn))


## The class's portrait for under its start (23 Oct's wheel disc, back in 0.12.1): art/people_new/<class>.png (the new
## face, as the card's), else art/people/, faded to nothing at its rim, made once.
static var _portraits := {}
static func wheel_portrait(cls: String) -> Texture2D:
	if _portraits.has(cls):
		return _portraits[cls]
	var tex: Texture2D = art_at("res://art/people_new/%s.png" % cls.to_lower())
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


## A node's radius in web units, by its web kind (or, on the old canvases, its flags).
func radius_of(nd: Dictionary) -> float:
	if nd.has("web_kind"):
		if str(nd["web_kind"]) == "small" and (zoom >= SMALL_ART_ZOOM or assume_pics):
			return float(_small_cap.get(str(nd.get("slot", "")), R_SMALL))
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
		"notable", "skill":
			return R_NOTABLE
		"start":
			return R_START
		"ring":
			return R_RING_NODE
	return R_SMALL


## Whether a node carries its picture (a notable, keystone, capstone, the start, a ring node); the smalls are dots.
static func big_kind(k: String) -> bool:
	return k in ["notable", "skill", "keystone", "capstone", "start", "ring"]


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
const PICK_OUTS := [4.0, 16.0, 28.0, 40.0, 52.0, 64.0, 76.0, 90.0, 105.0, 120.0, 140.0, 165.0, 190.0, 220.0]
func _draw_pick_labels() -> void:
	pick_label_rects = {}
	pick_label_hits = {}
	var canvas := Rect2(Vector2.ZERO, size)
	var names_r: Array = []                # the names' blocks this frame, read once (BUILD49 V)
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
			# a spot the canvas's edge pushed it to is placed again once a pan has moved it (BUILD51-U, item 5; review47: it
			# stayed out wide after the pan brought a cleaner spot into view); a free spot is kept as it was
			var held: bool = not bool(_pick_cache[ck][2]) or Vector2(_pick_cache[ck][3]) == cam
			if canvas.encloses(rc0) and held:
				best = rc0
				best_n = int(_pick_cache[ck][1])
		if best_n < 0:
			if names_r.is_empty():
				names_r = _axis.keys().map(func(ak): return block_rect(str(ak))).filter(func(br): return Rect2(br).size.x > 0.0)
			best_n = 1 << 30
			var edged := false                 # a spot before the one taken passed over for the canvas's edge (BUILD51-U)
			var off_seen := false
			for out in PICK_OUTS:
				for at in [p + Vector2(-sz.x / 2.0, r + out), p + Vector2(-sz.x / 2.0, -r - out - sz.y), p + Vector2(r + out + 2.0, -sz.y / 2.0),
						p + Vector2(-r - out - 2.0 - sz.x, -sz.y / 2.0), p + Vector2(r * 0.7 + out, r * 0.7 + out * 0.5), p + Vector2(-r * 0.7 - out - sz.x, r * 0.7 + out * 0.5),
						p + Vector2(r * 0.7 + out, -r * 0.7 - out * 0.5 - sz.y), p + Vector2(-r * 0.7 - out - sz.x, -r * 0.7 - out * 0.5 - sz.y)]:     # below, above, right, left, the four diagonals
					var rc := Rect2(at, sz)
					var n: int = (0 if canvas.encloses(rc) else 1000)
					off_seen = off_seen or n > 0
					if n < best_n:
						n += _covers_at(rc, id, names_r, best_n - n)
					if n < best_n:
						best_n = n
						best = rc
						edged = off_seen and n < 1000
					if best_n == 0:
						break
				if best_n == 0:
					break
			_pick_cache[ck] = [best.position - p, best_n, edged, cam]
		pick_label_rects[id] = best
		pick_label_hits[id] = best_n
		if not dry:
			var lead := Vector2(clampf(p.x, best.position.x, best.end.x), clampf(p.y, best.position.y, best.end.y))
			if lead.distance_to(p) > r + 10.0:
				draw_line(p + (lead - p).normalized() * (r + 2.0), lead, Color(pl[3], 0.7), 1.0, true)     # a lead from a plate set further out
			draw_rect(best, Color(Pal.BG, 0.88))
		_text(_font, best.position + Vector2(PICK_PAD, PICK_PAD + _font.get_ascent(12)), words, 12, pl[3])
	_pick_labels = []


## What a picked label could run into from `p` within `reach`: [how near p, centre, radius] for the nodes but `own`,
## [how near p, rect] for the names' blocks - nearest first, so a spot close in reads only the few it can reach.
func _pick_near(own: String, p: Vector2, reach: float) -> Array:
	var out: Array = []
	for oid in layout:
		if oid == own:
			continue
		var q: Vector2 = to_screen(layout[oid])
		if absf(q.x - p.x) <= reach and absf(q.y - p.y) <= reach:
			var rr: float = maxf(3.0, radius_of(node_of(oid)) * zoom) + 1.0
			out.append([q.distance_to(p) - rr, q, rr])
	for key in _axis:
		var lr: Rect2 = block_rect(str(key))
		if lr.size.x > 0.0:
			out.append([Vector2(clampf(p.x, lr.position.x, lr.end.x), clampf(p.y, lr.position.y, lr.end.y)).distance_to(p), lr])
	out.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	return out


## A name's block costs a picked label what a node does (0.12.2, the review: the runner's own name sits in its class's
## heart, where a pick's label used to land): it goes further out, over links, to a spot clear of both.
const PICK_NODE_COST := 100


## What a plate covers (PICK_NODE_COST a node or a name), reading `near` out to `reach` from its node and stopping once it
## reaches `stop` (a spot no better than the best so far).
func _pick_covers(rc: Rect2, near: Array, reach := INF, stop := 1 << 30) -> int:
	var n := 0
	for e in near:
		if float(e[0]) > reach or n >= stop:
			break
		if e.size() == 2:
			if Rect2(e[1]).intersects(rc):
				n += PICK_NODE_COST
		else:
			var q: Vector2 = e[1]
			if Vector2(clampf(q.x, rc.position.x, rc.end.x), clampf(q.y, rc.position.y, rc.end.y)).distance_to(q) < float(e[2]):
				n += PICK_NODE_COST
	return n


## How many nodes other than `own` a rect on the canvas covers, and the regions' names it runs into (every node read).
func label_covers(rc: Rect2, own: String) -> int:
	return _pick_covers(rc, _pick_near(own, rc.get_center(), INF))


## What a plate on the canvas covers (PICK_NODE_COST a node or a name), the nodes read from the hit grid under it alone
## (BUILD49 V: version two's 1,579 nodes, the near list sorted for each label cost 15-20 ms), stopping at `stop`.
func _covers_at(rc: Rect2, own: String, names_r: Array, stop := 1 << 30) -> int:
	var n := 0
	for br in names_r:
		if Rect2(br).intersects(rc):
			n += PICK_NODE_COST
			if n >= stop:
				return n
	_ensure_hit()
	var g: float = (maxf(3.0, R_CAPSTONE * zoom) + 1.0) / zoom
	var w0: Vector2 = to_web(rc.position) - Vector2(g, g)
	var w1: Vector2 = to_web(rc.end) + Vector2(g, g)
	for cx in range(floori(w0.x / HIT_CELL), floori(w1.x / HIT_CELL) + 1):
		for cy in range(floori(w0.y / HIT_CELL), floori(w1.y / HIT_CELL) + 1):
			for oid in _hit.get(Vector2i(cx, cy), []):
				if oid == own:
					continue
				var q: Vector2 = to_screen(layout[oid])
				var rr: float = maxf(3.0, radius_of(node_of(oid)) * zoom) + 1.0
				if Vector2(clampf(q.x, rc.position.x, rc.end.x), clampf(q.y, rc.position.y, rc.end.y)).distance_to(q) < rr:
					n += PICK_NODE_COST
					if n >= stop:
						return n
	return n


## The words queued so far, drawn now (the names before the picked label's plate goes over them).
func _flush_texts() -> void:
	for key in _texts:
		_tally("text:" + key)
		for t in _texts[key]:
			if not dry:
				draw_string(t[0], t[1], t[2], HORIZONTAL_ALIGNMENT_LEFT, -1, t[3], t[4])
	_texts = {}


var last_draw_us := 0                  # the last frame's time in _draw (µs; the smoke's and the probe's)


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	batches = 0
	nodes_drawn = 0
	emblem_rects = {}
	block_sizes = {}
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
		last_draw_us = Time.get_ticks_usec() - t0
		return
	var view := Rect2(Vector2.ZERO, size).grow(60.0)
	draw_under(view)
	_draw_links(view)
	draw_between(view)
	_draw_nodes(view)
	_draw_region_names(view)
	_flush_texts()                         # the names' words under the picked label's plate (it may sit over a name)
	_draw_pick_labels()
	# the words last, a font and size at a time
	for key in _texts:
		_tally("text:" + key)
		for t in _texts[key]:
			if not dry:
				draw_string(t[0], t[1], t[2], HORIZONTAL_ALIGNMENT_LEFT, -1, t[3], t[4])
	_texts = {}
	_atlas_flush()
	last_draw_us = Time.get_ticks_usec() - t0


## The nodes (BUILD49 V): read from the packed arrays, culled to the view. Below SMALL_ART_ZOOM a lesser node is a dot in
## its colour (_draw_dot, one or two cells of the atlas); the rest, and every node closer in, _draw_node.
func _draw_nodes(view: Rect2) -> void:
	if _ids.size() != layout.size():
		_pack_ids()
	var half: Vector2 = size / 2.0
	var dots: bool = zoom < SMALL_ART_ZOOM and nodes_are_web()
	var r_dot: float = maxf(DOT_MIN, R_SMALL * zoom)
	var disc: Texture2D = shape("disc", r_dot + 1.0)
	var hi: int = _ix.get(hover, -1)
	var si: int = _ix.get(selected, -1)
	var vx0: float = view.position.x
	var vy0: float = view.position.y
	var vx1: float = view.end.x
	var vy1: float = view.end.y
	if dots and _batch_key != "atlas":
		_tally("atlas")
	for i in range(_ids.size()):
		var p: Vector2 = (_pos[i] - cam) * zoom + half
		if p.x < vx0 or p.y < vy0 or p.x > vx1 or p.y > vy1:
			continue
		if dots and _kidx[i] == 0 and i != hi and i != si:
			nodes_drawn += 1
			var st: int = _st[i]
			if st == 0:                        # dark: a dot of its colour over the canvas (DARK_DOT)
				if not dry:
					draw_texture_rect(disc, Rect2(p.x - r_dot, p.y - r_dot, 2.0 * r_dot, 2.0 * r_dot), false, _dark[i])
			else:
				_draw_dot(i, st, p, r_dot, disc)
		else:
			_draw_node(_ids[i], p)


## A lesser node at the whole web: owned, lit in its colour with a glow; can take, ringed amber.
func _draw_dot(i: int, st: int, p: Vector2, r: float, disc: Texture2D) -> void:
	var tone: Color = _tones[i]
	if st == 2:
		_shape("disc", p, r * GLOW_R, Color(tone, GLOW))
		_dot(disc, p, r, tone)
	else:
		_dot(disc, p, r + 1.0, FRONTIER)
		_dot(disc, p, maxf(0.6, r - 0.6), Pal.CARD)


func _dot(tex: Texture2D, p: Vector2, r: float, col: Color) -> void:
	if _batch_key != "atlas":
		_tally("atlas")
	if not dry:
		draw_texture_rect(tex, Rect2(p.x - r, p.y - r, 2.0 * r, 2.0 * r), false, col)


## The links, under the nodes: lit in the node's colour between two owned, amber to one that can be taken, dim
## otherwise (a track's, an element's and the centre's in their colour, faint). Gathered by colour and width in web
## space once a state (_gather_links), moved to the screen a run at a time (one transform each, no per-link work).
var _link_runs := {}                   # [colour, lit] -> PackedVector2Array of pairs, web space
var _link_runs_sig := ""
## Every link is drawn dark, gathered once a layout (_dim_runs); the lit and the frontier ones go over them, gathered
## once a state from the owned nodes' links alone (_link_runs).
var _dim_runs := {}                    # colour -> PackedVector2Array of pairs, web space
var _by_node: Array = []               # node index -> the pair indices on it
func _draw_links(_view: Rect2) -> void:
	_ensure_bends()
	if _pair_n != _links_sig():
		_pair_list()
	var sig := "%s|%s" % [_state_sig, _pair_n]
	if sig != _link_runs_sig:
		_gather_links()
		_link_runs_sig = sig
	var xf := Transform2D(0.0, Vector2(zoom, zoom), 0.0, size / 2.0 - cam * zoom)
	var w: float = LINK_W * maxf(0.6, zoom)
	for col in _dim_runs:
		_tally("lines")
		if not dry:
			draw_multiline(xf * PackedVector2Array(_dim_runs[col]), col, w, true)
	for run in _link_runs:
		_tally("lines")
		if not dry:
			draw_multiline(xf * PackedVector2Array(_link_runs[run]), run[0], w * (1.6 if run[1] else 1.0), true)


func _gather_links() -> void:
	_link_runs = {}
	var seen := {}
	for i in range(_st.size()):
		if _st[i] != 2:
			continue
		for j in _by_node[i]:
			if seen.has(j):
				continue
			seen[j] = true
			var sa: int = _st[_pa[j]]
			var sb: int = _st[_pb[j]]
			var lit: bool = sa == 2 and sb == 2
			if not lit and sa + sb != 3:
				continue                  # owned to a dark one: its dark line stands
			var run := [_ptone[j] if lit else Color(FRONTIER, 0.85), lit]
			if not _link_runs.has(run):
				_link_runs[run] = PackedVector2Array()
			_link_runs[run].append_array(_pair_pts(j))


## A link's segments in web space: its two ends, or its bend's.
func _pair_pts(j: int) -> PackedVector2Array:
	var bent: PackedVector2Array = _pbend[j]
	if bent.is_empty():
		return PackedVector2Array([_pos[_pa[j]], _pos[_pb[j]]])
	var out := PackedVector2Array()
	for q in range(bent.size() - 1):
		out.append(bent[q])
		out.append(bent[q + 1])
	return out


## Every link once, as indices into the packed arrays, with its lit colour, its dark colour and its bend (link_colour's
## rule, worked once a layout and its bends).
var _pa := PackedInt32Array()
var _pb := PackedInt32Array()
var _ptone := PackedColorArray()
var _pdim := PackedColorArray()
var _pbend: Array = []
var _pair_n := ""
func _links_sig() -> String:
	return "%d|%d|%d" % [_ids.size(), links_all().size(), _bends.size()]


func _pair_list() -> void:
	_pa = PackedInt32Array()
	_pb = PackedInt32Array()
	_ptone = PackedColorArray()
	_pdim = PackedColorArray()
	_pbend = []
	var at := {}
	for i in range(_ids.size()):
		at[_ids[i]] = i
	var keep: Dictionary = _state
	_state = {}                            # link_colour's dark rule: neither end owned nor takeable
	var links: Dictionary = links_all()
	for a in links:
		for b in links[a]:
			if str(a) > str(b) or not at.has(a) or not at.has(b):
				continue
			_pa.append(at[a])
			_pb.append(at[b])
			_ptone.append(tone_of(link_key(str(a), str(b))))
			_pdim.append(link_colour(str(a), str(b)))
			_pbend.append(bend_of(str(a), str(b)))
	_state = keep
	_by_node = []
	_by_node.resize(_ids.size())
	for i in range(_ids.size()):
		_by_node[i] = []
	_dim_runs = {}
	for j in range(_pa.size()):
		_by_node[_pa[j]].append(j)
		_by_node[_pb[j]].append(j)
		var col: Color = _pdim[j]
		if not _dim_runs.has(col):
			_dim_runs[col] = PackedVector2Array()
		_dim_runs[col].append_array(_pair_pts(j))
	_pair_n = _links_sig()


## A reachable link's colour, lighter than the region's (or darker where the colour's near white already).
static func reach_tone(tone: Color) -> Color:
	return tone.lerp(Color.WHITE, 0.4) if tone.get_luminance() < 0.7 else tone.darkened(0.35)


## A link's colour: the region's where both ends are owned (a link between two regions takes the coloured one's: an
## element's, a join's, the centre's), amber from an owned node to one that can be taken, dim otherwise - in its
## region's colour, faint, inside the centre, an element or a join.
func link_colour(a: String, b: String) -> Color:
	var sa: Dictionary = _state.get(a, {})
	var sb: Dictionary = _state.get(b, {})
	var tone: Color = tone_of(link_key(a, b))
	if sa.get("taken", false) and sb.get("taken", false):
		return tone
	if (sa.get("taken", false) and sb.get("reach", false)) or (sb.get("taken", false) and sa.get("reach", false)):
		return Color(FRONTIER, 0.85)
	if tinted(a) or tinted(b):
		return Color(tone, ELEMENT_LINK_DIM)
	if str(_region.get(a, "")).begins_with("class:") and _track.get(a, "") != "" and _track.get(a, "") == _track.get(b, ""):
		return Color(tone_of(a), TRACK_LINK_DIM)     # a track's own links in its colour, faint (round six)
	return LINK_CLASS_DIM if str(_region.get(a, "")).begins_with("class:") else LINK_DIM


## Whose colour a link takes: the coloured end's (an element's, a join's, the centre's), else the end that isn't the
## start (BUILD49 V: a class's link lit in its track's colour, not the start's amber).
func link_key(a: String, b: String) -> String:
	if tinted(a):
		return a
	if tinted(b):
		return b
	return b if _track.get(a, "") == "start" else a


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


## The layout's signature, kept (merge 49's review: the sum walked all ~1,580 nodes every frame, a hover's redraw
## too): worked again only when the layout is a new one (lay_out), changes size, or layout_moved() says a place moved.
var _sig_cache := Vector3.ZERO
var _sig_of: Dictionary = {}           # the layout dictionary the signature was worked for
var _sig_n := -1
func layout_sig() -> Vector3:
	if not is_same(_sig_of, layout) or _sig_n != layout.size():
		_sig_cache = _layout_sig()
		_sig_of = layout
		_sig_n = layout.size()
	return _sig_cache


## A node's place changed in the layout as it stands: the kept signature (and so the bends) worked again.
func layout_moved() -> void:
	_sig_n = -1


## The bends worked for the layout as it stands: once a layout (the signature kept, layout_sig).
func _ensure_bends() -> void:
	if _bends_for != layout_sig():
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
	_bends_for = layout_sig()
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
		var tone: Color = ax.get("tone", Pal.TEXT)
		if sim != null and str(key) == "class:" + str(sim.cls):
			tone = Pal.ACCENT
		var dims: Dictionary = block_dims(key, zoom)
		var br: Rect2 = block_rect(key)
		_sprite(solid(), br, Color(Pal.BG, 0.78))     # the plate: a link under the name doesn't cut it (0.12.2); from the atlas (BUILD49 V)
		block_sizes[key] = [dims["ts"], dims["es"]]
		var wr: Rect2 = label_rect(key)
		var fs: int = int(round(dims["ts"]))
		_text(_font_bold, Vector2(wr.position.x, wr.get_center().y + fs * 0.36), words, fs, tone)
		var ers: Array = emblem_rects_of(key)
		for i in range(ers.size()):
			_sprite(atlased(ax["emblems"][i]), ers[i])
			emblem_rects["%s#%d" % [key, i]] = ers[i]


## Under everything: the paragon ring's dashed circle round the outside (the ring's own nodes sit on it).
func draw_under(view: Rect2) -> void:
	portrait_rect = Rect2()
	if sim != null and str(sim.cls) != "" and nodes_are_web() and _axis.has("class:" + str(sim.cls)):
		var face: Texture2D = wheel_portrait(str(sim.cls))
		var fc: Vector2 = block_rect("class:" + str(sim.cls)).get_center()     # on the class's name and its emblems (0.12.2, Matt; BUILD49 V: the block's middle)
		var fr: float = maxf(PORTRAIT_R * zoom, block_rect("class:" + str(sim.cls)).size.x / 2.0 + 10.0)
		if face != null and view.grow(fr).has_point(fc):
			portrait_rect = Rect2(fc - Vector2(fr, fr), Vector2(fr, fr) * 2.0)
			_sprite(atlased(face), portrait_rect, PORTRAIT_SHADE)
	var c: Vector2 = to_screen(Vector2.ZERO)
	var r: float = _ring_r * zoom
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
## them (their glyph below PIC_ZOOM); a small node from SMALL_ART_ZOOM its picture or its glyph (small_art_of). Its words
## go to the words' pass.
func _draw_node(id: String, p: Vector2) -> void:
	nodes_drawn += 1
	var nd: Dictionary = node_of(id)
	var st: Dictionary = _state.get(id, {})
	var k: String = str(_kind.get(id, nd.get("web_kind", "small")))
	var tone: Color = _tone.get(id, Pal.TEXT)
	var r: float = radius_of(nd) * zoom
	if big_kind(k) and k != "ring":
		r = maxf(r, BIG_MIN)               # a big node reads at the whole web (BUILD49 V)
	elif k == "small":
		r = maxf(r, DOT_MIN)
	var z: float = maxf(0.7, zoom)
	var taken: bool = st.get("taken", false)
	var reach: bool = st.get("reach", false)
	var diamond: bool = k == "keystone" or k == "capstone"
	var sq: String = "square" if k == "skill" else "disc"     # a skill a rounded square (round six)
	var fill: Color = Pal.BG
	var line: Color = Pal.CARD_LINE.lerp(tone, RING_DIM)
	var w: float = 1.0
	if taken:
		fill = Pal.CARD.lerp(tone, 0.55)
		line = tone
		w = 2.0
		_shape("diamond" if diamond else sq, p, r * GLOW_R, Color(tone, GLOW))
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
		_shape(sq, p, r + w / 2.0, line)
		_shape(sq, p, maxf(0.5, r - w / 2.0), fill)
	if big_kind(k):
		var pic: Texture2D = picture(picture_slug(nd))
		if pic != null and zoom >= PIC_ZOOM:
			var g: float = (r - 1.5 * z) * (1.42 if diamond else 1.7)
			var shade: Color = Color(1.25, 1.25, 1.25) if taken else (Color(1.05, 1.05, 1.05) if reach else Color(0.7, 0.7, 0.7))
			_sprite(atlased(pic), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), shade)
		elif glyph_of(nd) != "" and r >= 4.0:
			var g: float = r * 1.1
			_sprite(atlased(NodeGlyphs.texture(glyph_of(nd))), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	else:
		match small_art_of(id):
			"picture":
				var g: float = (r - 1.0 * z) * 1.7
				var shade: Color = Color(1.25, 1.25, 1.25) if taken else (Color(1.05, 1.05, 1.05) if reach else Color(0.7, 0.7, 0.7))
				_sprite(atlased(picture(picture_slug(nd))), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), shade)
			"glyph":
				var g: float = r * 1.15
				_sprite(atlased(NodeGlyphs.texture(glyph_of(nd))), Rect2(p - Vector2(g, g) / 2.0, Vector2(g, g)), tone if taken else (Pal.TEXT if reach else Pal.TEXT_3))
	var stack: Array = stack_of(id, nd)
	if not stack.is_empty() and zoom >= 1.0:
		var stack_v: String = "%d/%d" % [int(stack[0]), int(stack[1])]
		var sw: float = _font.get_string_size(stack_v, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var named: bool = zoom >= LABEL_ZOOM and big_kind(k) and str(nd.get("name", "")) != ""
		_text(_font, p + Vector2(-sw / 2.0, r + (28.0 if named else 13.0)), stack_v, 11, Pal.TEXT if taken else Pal.TEXT_3)     # under the name when it shows (0.12.2)
	# the name under a big node, from the label zoom (the hovered and the picked always: under the zoom, on a plate of
	# their own, after the nodes, where it covers the fewest - _draw_pick_labels)
	if (id == hover or id == selected) and (zoom < LABEL_ZOOM or not big_kind(k)) and k != "ring" and str(nd.get("name", "")) != "":     # every named node on hover, a lesser one too (BUILD49 V)
		_pick_labels.append([id, p, r, Pal.TEXT if taken or reach else Pal.TEXT_3])
	elif zoom >= LABEL_ZOOM and big_kind(k) and str(nd.get("name", "")) != "":
		var words: String = str(nd["name"])
		var tw: float = _font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		_text(_font, p + Vector2(-tw / 2.0, r + 14.0), words, 12, Pal.TEXT if taken or reach else Pal.TEXT_3)


# ------------------------------------------------------------------ input

## The node under a point on the canvas (BUILD49 V: the nodes within reach only, from the hit grid).
const HIT_CELL := 64.0
var _hit := {}                         # Vector2i cell -> ids, web space, built with the layout
var _hit_n := -1
func node_at(screen_p: Vector2) -> String:
	_ensure_hit()
	var w: Vector2 = to_web(screen_p)
	var reach: float = (maxf(12.0, R_CAPSTONE * zoom) + 4.0) / zoom
	var cand: Array = []
	for cx in range(floori((w.x - reach) / HIT_CELL), floori((w.x + reach) / HIT_CELL) + 1):
		for cy in range(floori((w.y - reach) / HIT_CELL), floori((w.y + reach) / HIT_CELL) + 1):
			cand.append_array(_hit.get(Vector2i(cx, cy), []))
	return _nearest_hit(screen_p, cand)


func _ensure_hit() -> void:
	if _hit_n != layout.size():
		_hit = {}
		for id in layout:
			var c := Vector2i(floori(layout[id].x / HIT_CELL), floori(layout[id].y / HIT_CELL))
			if not _hit.has(c):
				_hit[c] = []
			_hit[c].append(id)
		_hit_n = layout.size()


func _nearest_hit(screen_p: Vector2, cand: Array) -> String:
	var best := ""
	var best_d := INF
	for id in cand:
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
