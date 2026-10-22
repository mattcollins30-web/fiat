extends "res://scripts/ui/web_view.gd"
## The Map's web (22 Oct, docs/design/web_map_pitch.md §1): the atlas's three regions - the sites, the crews, the
## codes - off a centre on the Training canvas's base. A node is an atlas key; its state the sim's atlas (ranks as
## a stack, pathed from the region's entry); the Dial's points buy a rank.

const REGION_GAP := 500.0          # the three regions side by side across the canvas (it's wide, not tall)


func lay_out() -> void:
	layout = {}
	_trees = {}
	_axis = {}
	for t in Data.MAP_WEB:
		_trees[t["name"]] = t
		var d := Vector2.RIGHT
		var at := Vector2((float(t["column"]) - 1.0) * REGION_GAP - 1.5 * Data.MAP_SPINE_STEP * STEP, 0.0)
		var side: Vector2 = d.orthogonal()
		for i in range(t["nodes"].size()):
			var a: Array = t["nodes"][i]["at"]
			layout["%s/%d" % [t["name"], i]] = at + d * (float(a[0]) * STEP) + side * (float(a[1]) * ROW)
		var tone: Color = Pal.ACCENT if t["column"] == 2 else Pal.TEXT
		# the name over the region's middle, clear of its top branch
		_axis[t["name"]] = {"at": at, "dir": d, "tone": tone, "label_at": at + d * (1.5 * Data.MAP_SPINE_STEP * STEP) + Vector2(0, -(Data.MAP_BRANCH_Y * ROW + 26.0))}
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


func draw_between(_view: Rect2) -> void:
	pass


func focus_named(words: String) -> void:
	match words:
		"The whole Dial":
			focus_all()
		_:
			focus_tree(words)
