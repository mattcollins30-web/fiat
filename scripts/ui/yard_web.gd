extends "res://scripts/ui/web_view.gd"
## The Pitch's web (22 Oct, docs/design/web_map_pitch.md §2): the eight buildings as regions off the centre on the
## Training canvas's base. A building's five columns are forks along its spine - the two picks of a column, one or
## the other, as now, each linked to both of the column before - and its ranks a chain past them. Tins and salvage
## pay as now; the sim's Yard rules (the columns' gates, the prices) are the state.

const Fmt := preload("res://scripts/ui/fmt.gd")
const R_YARD := 150.0              # the lanes start this far from the centre


## Eight buildings' lanes out from the centre at 45° each: the star, as Training's (Matt, 22 Oct: one layout for the
## player across the three webs); the name past each lane's end.
func lay_out() -> void:
	layout = {}
	_trees = {}
	_axis = {}
	for t in Data.YARD_WEB:
		_trees[t["name"]] = t
		var d := Vector2.from_angle(deg_to_rad(float(t["angle"])))
		var at: Vector2 = d * R_YARD
		var side: Vector2 = d.orthogonal()
		for i in range(t["nodes"].size()):
			var a: Array = t["nodes"][i]["at"]
			layout["%s/%d" % [t["name"], i]] = at + d * (float(a[0]) * STEP) + side * (float(a[1]) * ROW)
		_axis[t["name"]] = {"at": at, "dir": d, "tone": Pal.ACCENT, "label_at": at + d * (8.4 * STEP + 40.0), "align": (-1 if d.x < -0.3 else (1 if d.x > 0.3 else 0))}     # the name past the lane's end, running away from it
	_find_bounds()
	_bounds = _bounds.grow_individual(0.0, 160.0, 0.0, 60.0)     # the Bench's name over its lane, under the corner's buttons


## A building whose room isn't open yet reads scrambled (20 Oct, Matt: "encrypted until they unlock").
func node_of(id: String) -> Dictionary:
	var nd: Dictionary = Data.yard_node(id)
	if nd.is_empty() or sim == null or sim.room_open(sim.building_room(str(nd["yard"]))):
		return nd
	var out := nd.duplicate()
	out["name"] = Fmt.scramble(str(nd["name"]))
	return out


func links_all() -> Dictionary:
	return Data.yard_links()


func state_sig() -> String:
	return "%s|%s|%d|%d|%s|%s|%s|%s" % [str(sim.yard_picks), str(sim.yard_ranks), int(sim.cash), sim.yard_cols(), str(sim.salvage), str(sim.on_mission()), selected, str(sim.unlocked)]     # the rooms opening unscramble the names (the review)


func state_for(id: String) -> Dictionary:
	var nd: Dictionary = Data.yard_node(id)
	var key: String = str(nd["yard"])
	if nd.has("rank"):
		var r: int = int(nd["rank"])
		var have: int = sim.yard_rank(key)
		var next_here: bool = have == r - 1 or (r == 5 and have >= 4)     # the fifth node is every rank from the fifth on (bought again and again)
		var rblock: String = sim.yard_rank_block(key) if next_here else ("rank %d first" % (r - 1) if have < r - 1 else "")
		var ropen: bool = next_here and (rblock == "" or rblock.begins_with("Short") or rblock.begins_with("Wants"))
		return {"taken": have >= r, "active": have >= r, "reach": ropen, "theirs": false, "cost": sim.yard_rank_cost(key) if next_here else 0, "block": rblock}
	var c: int = int(nd["col"])
	var side: String = str(nd["side"])
	var built: String = sim.yard_side(key, c)
	var block: String = sim.yard_pick_block(key, c, side)
	var open: bool = block == "" or block.begins_with("Short") or block.begins_with("Wants")     # open but for the price: drawn as reachable
	return {"taken": built == side, "active": built == side, "reach": built != side and open, "theirs": built != "" and built != side, "cost": sim.yard_pick_cost(key, c), "block": block}


func stack_of(_id: String, _nd: Dictionary) -> Array:
	return []                                 # the ranks past the fifth are the region's words ("rank 7")


func region_words(tn: String) -> String:
	var t: Dictionary = _trees[tn]
	var key: String = str(t["yard"])
	var built := 0
	for c in range(5):
		if sim.yard_side(key, c) != "":
			built += 1
	return "%s · %d of 5 built · rank %d" % [tn, built, sim.yard_rank(key)]


func level_tag(_nd: Dictionary) -> Array:
	return []


func backdrop_slug() -> String:
	return "pitch"


func picture_slug(nd: Dictionary) -> String:
	if nd.has("pick"):
		var b: Dictionary = Data.yard_building(str(nd["yard"]))
		return "pick_%s_%s" % [str(nd["yard"]), str(b["picks"][int(nd["col"])][0 if nd["side"] == "a" else 1]["id"])]     # art/nodes/pick_<building>_<id>.png
	return "pick_%s_rank" % str(nd["yard"])


func glyph_of(nd: Dictionary) -> String:
	if nd.has("pick"):
		var b: Dictionary = Data.yard_building(str(nd["yard"]))
		return NodeGlyphs.of_pick(b["picks"][int(nd["col"])][0 if nd["side"] == "a" else 1], str(nd["yard"]))
	return "star"


func draw_between(_view: Rect2) -> void:
	pass


func focus_named(words: String) -> void:
	if words == "The whole Pitch":
		focus_all()
	else:
		focus_tree(words)
