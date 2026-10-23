extends "res://scripts/ui/web_view.gd"
## The Map's web (22 Oct, docs/design/web_map_pitch.md §1): the atlas's three regions - the sites, the crews, the
## codes - off a centre on the Training canvas's base. A node is an atlas key; its state the sim's atlas (ranks as
## a stack, pathed from the region's entry); the Dial's points buy a rank.

const R_MAP := 90.0                # the regions' entries this far from the centre
const MAP_ANGLES := {0: 180.0, 1: -60.0, 2: 60.0}     # the sites out to the left, the crews up and right, the codes down and right: the star, as Training's


## Three regions out from a centre at their angles (Matt, 22 Oct: "the star like map on the class tree is what's
## needed for both - same layout so it's consistent for a player"); the name past each lane's end.
## The names stay where this canvas lays them (the starter's label is Training's: Matt, 23 Oct, of the class, element
## and Pitch regions).
func _labels_by_entry() -> void:
	pass


func lay_out() -> void:
	layout = {}
	_trees = {}
	_axis = {}
	for t in Data.MAP_WEB:
		_trees[t["name"]] = t
		var d := Vector2.from_angle(deg_to_rad(float(MAP_ANGLES[int(t["column"])])))
		var at: Vector2 = d * R_MAP
		var side: Vector2 = d.orthogonal()
		for i in range(t["nodes"].size()):
			var a: Array = t["nodes"][i]["at"]
			layout["%s/%d" % [t["name"], i]] = at + d * (float(a[0]) * STEP) + side * (float(a[1]) * ROW)
		var tone: Color = Pal.ACCENT if t["column"] == 2 else Pal.TEXT
		# the name past the lane's end, running away from it
		_axis[t["name"]] = {"at": at, "dir": d, "tone": tone, "label_at": at + d * (3.0 * Data.MAP_SPINE_STEP * STEP + 40.0), "align": (-1 if d.x < -0.3 else (1 if d.x > 0.3 else 0))}
	_find_bounds()


func node_of(id: String) -> Dictionary:
	return Data.map_node(id)


func links_all() -> Dictionary:
	return Data.map_links()


func state_sig() -> String:
	return "%s|%d|%s|%s" % [str(sim.atlas), sim.atlas_points, selected, str(sim.on_mission())]


func state_for(id: String) -> Dictionary:
	var nd: Dictionary = Data.map_node(id)
	var key: String = str(nd["key"])
	var rank: int = sim.atlas_rank(key)
	var top: int = int(Data.atlas_of(key)["max"])
	var block: String = sim.atlas_block(key, true)
	return {"taken": rank > 0, "active": rank > 0, "reach": rank < top and block == "", "theirs": false, "cost": 1, "block": block}


func stack_of(_id: String, nd: Dictionary) -> Array:
	var key: String = str(nd["key"])
	var top: int = int(Data.atlas_of(key)["max"])
	return [sim.atlas_rank(key), top] if top > 1 else []


func region_words(tn: String) -> String:
	var t: Dictionary = _trees[tn]
	var pts: int = sim.atlas_in_lane(int(t["column"]))
	return "%s · %d point%s in" % [tn, pts, "" if pts == 1 else "s"]


func level_tag(_nd: Dictionary) -> Array:
	return []


func glyph_of(nd: Dictionary) -> String:
	return NodeGlyphs.of_atlas(str(nd["key"])) if not nd.get("filler", false) else ""


func backdrop_slug() -> String:
	return "dial"


func picture_slug(nd: Dictionary) -> String:
	if nd.get("filler", false):
		return "map_f_" + slug_of(str(nd.get("name", "")))     # art/nodes/map_f_<slug>.png (the second wave, 23 Oct): never a Training node's
	return "map_" + str(nd["key"])     # art/nodes/map_<key>.png (the manifest, 22 Oct)


func draw_between(_view: Rect2) -> void:
	pass


func focus_named(words: String) -> void:
	match words:
		"The whole Dial":
			focus_all()
		_:
			focus_tree(words)
